module Inbound
  class MessageProcessorService
    def initialize(user:, message_text:, source: "sms")
      @user = user
      @message = message_text.strip
      @source = source
      @baby = user.babies.first
    end

    def process
      return error_result("No baby profile found. Please set up a baby first.") unless @baby
      return error_result("Message is empty.") if @message.blank?

      # Parse with Gemini AI
      parsed_actions = GeminiParserService.new(@message).parse

      # Create records
      results = RecordCreatorService.new(@user, @baby, parsed_actions).create_all

      # Send email confirmation
      send_confirmation(results)

      results
    end

    private

    def error_result(msg)
      [{ success: false, message: msg }]
    end

    def send_confirmation(results)
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
  end
end
