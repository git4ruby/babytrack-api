class Api::V1::TelegramController < ApplicationController
  skip_before_action :authenticate_user!

  # POST /api/v1/telegram/webhook
  def webhook
    message = params.dig("message")
    return head :ok unless message

    chat_id = message.dig("chat", "id")&.to_s
    text = message.dig("text")&.strip
    username = message.dig("from", "username")

    Rails.logger.info("Telegram from chat #{chat_id} (@#{username}): #{text&.truncate(100)}")

    return head :ok if text.blank?

    # Handle /start command — link account
    if text.start_with?("/start")
      handle_start(chat_id, text, username)
      return head :ok
    end

    # Handle /help command
    if text == "/help"
      send_telegram(chat_id, help_message)
      return head :ok
    end

    # Find user by telegram_chat_id
    user = User.find_by(telegram_chat_id: chat_id)

    unless user
      send_telegram(chat_id, "Your Telegram is not linked to a LullaTrack account.\n\nTo link: go to Settings in the app, click 'Link Telegram', and follow the instructions.")
      return head :ok
    end

    # Process message
    InboundMessageJob.perform_later(
      user_id: user.id,
      message: text,
      source: "telegram"
    )

    send_telegram(chat_id, "Got it! Processing...")
    head :ok
  end

  private

  def handle_start(chat_id, text, username)
    # /start link_TOKEN format — strip the "link_" prefix
    raw_token = text.split(" ").last
    token = raw_token&.sub(/^link_/, "")
    if token.present? && token != "/start"
      user = User.find_by(telegram_link_token: token)
      if user
        user.update!(telegram_chat_id: chat_id, telegram_link_token: nil)
        send_telegram(chat_id, "Linked to #{user.name}'s LullaTrack account!\n\nYou can now send messages to log feeds, diapers, and more.\n\nTry: bottle 90ml\n\nSend /help for all commands.")
        return
      end
    end

    send_telegram(chat_id, "Welcome to LullaTrack!\n\nTo get started, link your account:\n1. Go to lullatrack.com → Settings\n2. Click 'Link Telegram'\n3. It will send you back here with your account linked\n\nOr send /help for more info.")
  end

  def help_message
    <<~MSG
      LullaTrack Bot — Log baby data via Telegram

      Examples:
      • bottle 90ml 2:30pm
      • breastfeed left 20min
      • diaper wet
      • diaper poop yellow seedy
      • pump 120ml stored in fridge
      • weight 3.5kg
      • milestone: first smile
      • Wet - 3, Poop - 2

      You can also send multiple days:
      03/26
      1:25 PM - 80ml
      3:40 PM - 70ml

      All records get a confirmation email.
    MSG
  end

  def send_telegram(chat_id, text)
    token = ENV["TELEGRAM_BOT_TOKEN"]
    return unless token

    uri = URI("https://api.telegram.org/bot#{token}/sendMessage")
    Net::HTTP.post_form(uri, { chat_id: chat_id, text: text })
  rescue => e
    Rails.logger.error("Telegram send error: #{e.message}")
  end
end
