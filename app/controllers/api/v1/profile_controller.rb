class Api::V1::ProfileController < ApplicationController
  # GET /api/v1/profile
  def show
    render json: {
      data: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        role: current_user.role,
        phone_number: current_user.phone_number,
        sms_enabled: current_user.sms_enabled,
        telegram_linked: current_user.telegram_chat_id.present?,
        telegram_accounts: parse_telegram_accounts(current_user.telegram_chat_id)
      }
    }
  end

  # PATCH /api/v1/profile
  def update
    if current_user.update(profile_params)
      render json: {
        data: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name,
          phone_number: current_user.phone_number
        }
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/profile/password
  def change_password
    unless current_user.valid_password?(params[:current_password])
      render json: { errors: [ "Current password is incorrect" ] }, status: :unprocessable_entity
      return
    end

    if params[:new_password] != params[:new_password_confirmation]
      render json: { errors: [ "New passwords don't match" ] }, status: :unprocessable_entity
      return
    end

    if params[:new_password].length < 6
      render json: { errors: [ "New password must be at least 6 characters" ] }, status: :unprocessable_entity
      return
    end

    current_user.password = params[:new_password]
    if current_user.save
      render json: { message: "Password updated successfully" }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/profile/telegram_link
  def telegram_link
    token = SecureRandom.hex(16)
    current_user.update!(telegram_link_token: token)
    bot_username = "LullaTrackBot"
    link = "https://t.me/#{bot_username}?start=link_#{token}"
    render json: { data: { link: link, token: token } }
  end

  # DELETE /api/v1/profile/telegram_unlink
  def telegram_unlink
    if params[:chat_id].present?
      # Unlink specific account
      accounts = current_user.telegram_chat_id.to_s.split(",").map(&:strip)
      accounts.reject! { |a| a.start_with?(params[:chat_id]) }
      current_user.update!(telegram_chat_id: accounts.any? ? accounts.join(",") : nil)
    else
      current_user.update!(telegram_chat_id: nil, telegram_link_token: nil)
    end
    render json: { message: "Telegram unlinked" }
  end

  private

  def parse_telegram_accounts(raw)
    return [] unless raw.present?
    raw.split(",").map(&:strip).map do |entry|
      parts = entry.split("|")
      { chat_id: parts[0], label: parts[1] || "Unknown" }
    end
  end

  def profile_params
    params.require(:user).permit(:name, :phone_number)
  end
end
