require "net/imap"
require "mail"

class GmailPollJob < ApplicationJob
  queue_as :default

  def perform
    gmail_address = ENV["GMAIL_ADDRESS"]
    gmail_password = ENV["GMAIL_APP_PASSWORD"]

    return Rails.logger.warn("Gmail not configured") unless gmail_address && gmail_password

    imap = Net::IMAP.new("imap.gmail.com", port: 993, ssl: true)
    imap.login(gmail_address, gmail_password)
    imap.select("INBOX")

    # Fetch unread messages
    uids = imap.search(["NOT", "SEEN"])

    uids.each do |uid|
      begin
        msg = imap.fetch(uid, "RFC822")[0].attr["RFC822"]
        email = Mail.new(msg)

        from_email = email.from&.first&.downcase&.strip
        body = extract_body(email)

        Rails.logger.info("Email received from #{from_email}: #{body.truncate(100)}")

        # Find user by email
        user = User.find_by("LOWER(email) = ?", from_email)

        if user && body.present?
          InboundMessageJob.perform_later(
            user_id: user.id,
            message: body,
            source: "email"
          )
        else
          Rails.logger.warn("Email from unknown sender or empty body: #{from_email}")
        end

        # Mark as read and delete from inbox (move to trash)
        imap.store(uid, "+FLAGS", [:Seen, :Deleted])
      rescue => e
        Rails.logger.error("Failed to process email UID #{uid}: #{e.message}")
        imap.store(uid, "+FLAGS", [:Seen]) # Mark read anyway to avoid reprocessing
      end
    end

    imap.expunge  # permanently remove deleted messages
    imap.logout
    imap.disconnect
  rescue => e
    Rails.logger.error("Gmail poll error: #{e.message}")
  end

  private

  def extract_body(email)
    if email.multipart?
      part = email.text_part || email.parts.first
      text = part&.decoded || ""
    else
      text = email.decoded || ""
    end

    # Strip email signatures and quoted replies
    text = text.split(/^--\s*$/).first || text        # signature separator
    text = text.split(/^On .+ wrote:/).first || text   # reply quote
    text = text.split(/^>/).first || text               # quoted lines
    text.strip.truncate(500)
  end
end
