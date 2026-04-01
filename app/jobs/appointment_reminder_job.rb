class AppointmentReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Find appointments with reminders due
    Appointment.needing_reminder.includes(:baby, :user).each do |appt|
      ReminderMailer.appointment_reminder(appt).deliver_later
      appt.update(reminder_sent: true)
      Rails.logger.info("Sent appointment reminder for '#{appt.title}' to #{appt.user.email}")
    end

    # Also check appointments in next 24 hours that haven't had reminder sent
    upcoming = Appointment.status_upcoming
      .where(reminder_sent: false)
      .where(scheduled_at: Time.current..24.hours.from_now)
      .includes(:baby, :user)

    upcoming.each do |appt|
      ReminderMailer.appointment_reminder(appt).deliver_later
      appt.update(reminder_sent: true)
      Rails.logger.info("Sent 24h appointment reminder for '#{appt.title}' to #{appt.user.email}")
    end
  end
end
