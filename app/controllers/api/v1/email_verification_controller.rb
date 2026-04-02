class Api::V1::EmailVerificationController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :verify ]

  # POST /api/v1/email/send_verification
  def send_verification
    if current_user.email_verified?
      render json: { message: "Email already verified" }
      return
    end

    token = SecureRandom.hex(20)
    current_user.update!(email_verification_token: token)

    VerificationMailer.verify_email(current_user, token).deliver_later
    render json: { message: "Verification email sent" }
  end

  # GET /api/v1/email/verify?token=
  def verify
    user = User.find_by(email_verification_token: params[:token])

    unless user
      render json: { error: "Invalid verification link" }, status: :not_found
      return
    end

    user.update!(email_verified: true, email_verification_token: nil)
    render json: { message: "Email verified!" }
  end
end
