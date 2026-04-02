module Inbound
  class MessageProcessorService
    def initialize(user:, message_text:, source: "sms", reply_chat_id: nil)
      @user = user
      @message = message_text.strip
      @source = source
      @reply_chat_id = reply_chat_id
    end

    def process
      if @user.babies.empty?
        return error_with_email("No baby profile found. Please set up a baby in the app first.")
      end
      return error_result("Message is empty.") if @message.blank?

      @baby = resolve_baby
      if @baby.nil?
        return error_with_email(@baby_error)
      end

      # Parse with Gemini AI
      parsed_actions = GeminiParserService.new(@message).parse

      # Create records
      results = RecordCreatorService.new(@user, @baby, parsed_actions).create_all

      # Prepend baby name info if user has multiple babies
      if @user.babies.count > 1
        results.unshift({ success: true, message: "Recording for: #{@baby.name}", skipped: true, type: "info" })
      end

      # Send confirmation via the same channel
      if @source == "telegram"
        send_telegram_reply(results)
      else
        send_email_confirmation(results)
      end

      results
    end

    private

    def resolve_baby
      babies = @user.babies

      # Only one baby — no ambiguity
      return babies.first if babies.count == 1

      # Check if message contains a baby name
      babies.each do |baby|
        first_name = baby.name.split.first.downcase
        if @message.downcase.include?(first_name)
          Rails.logger.info("Inbound: matched baby '#{baby.name}' by name in message")
          # Strip the baby name from the message so it doesn't confuse the parser
          @message = @message.gsub(/\b#{Regexp.escape(first_name)}\b/i, "").strip
          return baby
        end
      end

      # No name found — don't guess, reject the message
      baby_names = babies.map { |b| b.name.split.first }.join(", ")
      @baby_error = "You have multiple babies (#{baby_names}). Please include the baby's name in your message, e.g. \"#{babies.first.name.split.first} bottle 90ml\". No data was added."
      Rails.logger.warn("Inbound: multiple babies, no name in message — rejecting")
      nil
    end

    def error_result(msg)
      [ { success: false, message: msg } ]
    end

    def error_with_email(msg)
      results = [ { success: false, message: msg } ]
      @baby = @user.babies.first
      if @baby
        if @source == "telegram"
          send_telegram_reply(results)
        else
          send_email_confirmation(results)
        end
      end
      results
    end

    def send_email_confirmation(results)
      InboundConfirmationMailer.log_confirmation(
        user: @user,
        baby: @baby,
        results: results,
        source: @source,
        original_message: @message
      ).deliver_later
    rescue => e
      Rails.logger.error("Failed to send confirmation email: #{e.message}")
    end

    def send_telegram_reply(results)
      token = ENV["TELEGRAM_BOT_TOKEN"]
      return unless token

      chat_id = @reply_chat_id || @user.telegram_chat_id&.split(",")&.first&.split("|")&.first
      return unless chat_id

      lines = results.map { |r| "#{r[:success] ? '✅' : '❌'} #{r[:message]}" }
      text = "#{@baby.name}:\n#{lines.join("\n")}"

      uri = URI("https://api.telegram.org/bot#{token}/sendMessage")
      Net::HTTP.post_form(uri, { chat_id: chat_id, text: text })
    rescue => e
      Rails.logger.error("Failed to send Telegram reply: #{e.message}")
    end
  end
end
