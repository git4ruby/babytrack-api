class PasswordMailer < ApplicationMailer
  def reset_instructions(user, token)
    @user = user
    @token = token
    @reset_url = "#{ENV.fetch('FRONTEND_URL', 'https://lullatrack.com')}/reset-password?token=#{token}"

    mail(to: user.email, subject: "LullaTrack: Reset your password")
  end
end
