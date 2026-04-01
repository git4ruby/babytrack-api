class VaccinationAlertJob < ApplicationJob
  queue_as :default

  def perform
    Baby.includes(:user).find_each do |baby|
      next unless baby.user&.email

      # Find vaccines due within 7 days, not yet administered, reminder not sent
      due_vaccines = baby.vaccinations.pending.where(reminder_sent: false).select do |v|
        v.recommended_date && v.recommended_date <= 7.days.from_now.to_date && v.recommended_date >= Date.current
      end

      next if due_vaccines.empty?

      ReminderMailer.vaccination_alert(baby, baby.user, due_vaccines).deliver_later
      due_vaccines.each { |v| v.update(reminder_sent: true) }
      Rails.logger.info("Sent vaccination alert for #{baby.name}: #{due_vaccines.map(&:vaccine_name).join(', ')}")
    end
  end
end
