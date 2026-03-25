class Appointment < ApplicationRecord
  belongs_to :baby
  belongs_to :user

  enum :appointment_type, {
    well_visit: "well_visit",
    specialist: "specialist",
    followup: "followup",
    other: "other"
  }, prefix: true

  enum :status, {
    upcoming: "upcoming",
    completed: "completed",
    cancelled: "cancelled"
  }, prefix: true

  validates :title, presence: true
  validates :scheduled_at, presence: true
  validates :appointment_type, presence: true
  validates :status, presence: true

  scope :future, -> { status_upcoming.where("scheduled_at > ?", Time.current).order(scheduled_at: :asc) }
  scope :past, -> { where("scheduled_at <= ?", Time.current).order(scheduled_at: :desc) }
  scope :needing_reminder, -> {
    status_upcoming
      .where(reminder_sent: false)
      .where.not(reminder_at: nil)
      .where("reminder_at <= ?", Time.current)
  }
end
