class ReminderMailer < ApplicationMailer
  def appointment_reminder(appointment)
    @appointment = appointment
    @baby = appointment.baby
    @user = appointment.user

    mail(
      to: @user.email,
      subject: "BabyTrack: Reminder — #{@appointment.title} for #{@baby.name}"
    )
  end

  def vaccination_alert(baby, user, vaccines)
    @baby = baby
    @user = user
    @vaccines = vaccines

    mail(
      to: user.email,
      subject: "BabyTrack: #{vaccines.size} vaccine(s) due soon for #{baby.name}"
    )
  end
end
