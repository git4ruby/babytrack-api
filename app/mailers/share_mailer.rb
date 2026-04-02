class ShareMailer < ApplicationMailer
  def invite(share, inviter, baby)
    @share = share
    @inviter = inviter
    @baby = baby
    @accept_url = "#{ENV.fetch('FRONTEND_URL', 'https://lullatrack.com')}/accept-invite?token=#{share.invite_token}"

    mail(to: share.invite_email, subject: "LullaTrack: #{inviter.name} invited you to track #{baby.name}")
  end
end
