class VerificationMailer < ApplicationMailer
  def verify_email(user, token)
    @user = user
    @verify_url = "#{ENV.fetch('FRONTEND_URL', 'https://lullatrack.com')}/verify-email?token=#{token}"

    mail(to: user.email, subject: "LullaTrack: Verify your email")
  end
end
