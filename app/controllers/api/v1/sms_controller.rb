class Api::V1::SmsController < ApplicationController
  skip_before_action :authenticate_user!

  # POST /api/v1/sms/incoming — Twilio webhook
  def incoming
    from_number = params["From"]&.gsub(/\s+/, "")
    body = params["Body"]&.strip

    Rails.logger.info("SMS received from #{from_number}: #{body}")

    # Find user by phone number
    user = User.find_by(phone_number: from_number)

    unless user
      Rails.logger.warn("SMS from unknown number: #{from_number}")
      render xml: twiml_response("This phone number is not linked to a BabyTrack account. Please link your number in the app settings.")
      return
    end

    # Process asynchronously
    InboundMessageJob.perform_later(
      user_id: user.id,
      message: body,
      source: "sms"
    )

    render xml: twiml_response("Got it! Processing your message.")
  end

  private

  def twiml_response(message)
    # Minimal TwiML response (no SMS reply to save cost — confirmation via email)
    # Return empty TwiML to avoid sending SMS reply
    '<?xml version="1.0" encoding="UTF-8"?><Response></Response>'
  end
end
