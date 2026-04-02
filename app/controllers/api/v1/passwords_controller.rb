class Api::V1::PasswordsController < ApplicationController
  skip_before_action :authenticate_user!

  # POST /api/v1/password/forgot
  def forgot
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user
      token = SecureRandom.hex(20)
      user.update!(reset_password_token: Devise.token_generator.digest(User, :reset_password_token, token),
                   reset_password_sent_at: Time.current)

      PasswordMailer.reset_instructions(user, token).deliver_later
    end

    # Always return success to prevent email enumeration
    render json: { message: "If an account exists with that email, you will receive password reset instructions." }
  end

  # POST /api/v1/password/reset
  def reset
    original_token = params[:token]
    hashed_token = Devise.token_generator.digest(User, :reset_password_token, original_token)
    user = User.find_by(reset_password_token: hashed_token)

    unless user
      render json: { errors: [ "Invalid or expired reset token" ] }, status: :unprocessable_entity
      return
    end

    if user.reset_password_sent_at < 2.hours.ago
      render json: { errors: [ "Reset token has expired. Please request a new one." ] }, status: :unprocessable_entity
      return
    end

    if params[:password].length < 6
      render json: { errors: [ "Password must be at least 6 characters" ] }, status: :unprocessable_entity
      return
    end

    user.password = params[:password]
    user.reset_password_token = nil
    user.reset_password_sent_at = nil
    user.save!

    render json: { message: "Password has been reset. You can now sign in." }
  end
end
