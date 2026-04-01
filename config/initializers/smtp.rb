# Gmail SMTP for sending confirmation emails
if ENV["GMAIL_ADDRESS"].present? && ENV["GMAIL_APP_PASSWORD"].present?
  Rails.application.config.action_mailer.delivery_method = :smtp
  Rails.application.config.action_mailer.smtp_settings = {
    address: "smtp.gmail.com",
    port: 587,
    user_name: ENV["GMAIL_ADDRESS"],
    password: ENV["GMAIL_APP_PASSWORD"],
    authentication: "plain",
    enable_starttls_auto: true
  }
  Rails.application.config.action_mailer.default_options = {
    from: "BabyTrack <#{ENV['GMAIL_ADDRESS']}>"
  }
end
