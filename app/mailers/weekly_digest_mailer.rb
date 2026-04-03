class WeeklyDigestMailer < ApplicationMailer
  def digest(user, baby, stats, from_date, to_date)
    @user = user
    @baby = baby
    @stats = stats
    @from_date = from_date
    @to_date = to_date

    mail(
      to: @user.email,
      subject: "LullaTrack: Weekly Summary for #{@baby.name} (#{@from_date.strftime('%b %d')} - #{@to_date.strftime('%b %d')})"
    )
  end
end
