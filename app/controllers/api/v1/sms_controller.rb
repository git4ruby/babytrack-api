class Api::V1::SmsController < ApplicationController
  skip_before_action :authenticate_user!

  # POST /api/v1/sms/incoming — Twilio webhook
  def incoming
    from_number = params["From"]&.gsub(/\s+/, "")
    body = params["Body"]&.strip

    Rails.logger.info("SMS received from #{from_number}: #{body}")

    # Find user by phone number (supports multiple comma-separated numbers)
    user = User.where("phone_number LIKE ?", "%#{from_number}%").first

    unless user
      Rails.logger.warn("SMS from unknown number: #{from_number}")
      render xml: twiml_response
      return
    end

    # Process asynchronously
    InboundMessageJob.perform_later(
      user_id: user.id,
      message: body,
      source: "sms"
    )

    render xml: twiml_response
  end

  private

  def twiml_response
    '<?xml version="1.0" encoding="UTF-8"?><Response></Response>'
  end
end
