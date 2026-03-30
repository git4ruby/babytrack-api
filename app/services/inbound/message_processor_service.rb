module Inbound
  class MessageProcessorService
    def initialize(user:, message_text:, source: "sms")
      @user = user
      @message = message_text.strip
      @source = source
    end

    def process
      return error_result("No baby profile found. Please set up a baby first.") if @user.babies.empty?
      return error_result("Message is empty.") if @message.blank?

      @baby = resolve_baby
      return error_result(@baby_error) if @baby.nil?

      # Parse with Gemini AI
      parsed_actions = GeminiParserService.new(@message).parse

      # Create records
      results = RecordCreatorService.new(@user, @baby, parsed_actions).create_all

      # Prepend baby name info if user has multiple babies
      if @user.babies.count > 1
        results.unshift({ success: true, message: "Recording for: #{@baby.name}", skipped: true, type: "info" })
      end

      # Send email confirmation
      send_confirmation(results)

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

      # No name found — use the most recently active baby
      # (the one with the latest feeding or diaper change)
      most_active = babies.left_joins(:feedings, :diaper_changes)
        .select("babies.*, GREATEST(MAX(feedings.started_at), MAX(diaper_changes.changed_at)) AS last_activity")
        .group("babies.id")
        .order(Arel.sql("GREATEST(MAX(feedings.started_at), MAX(diaper_changes.changed_at)) DESC NULLS LAST"))
        .first

      if most_active
        Rails.logger.info("Inbound: no baby name in message, using most recently active: #{most_active.name}")
        return most_active
      end

      # Fallback to first baby
      babies.first
    end

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
