class Vaccination < ApplicationRecord
  belongs_to :baby

  enum :status, { pending: "pending", administered: "administered", skipped: "skipped" }

  validates :vaccine_name, presence: true
  validates :recommended_age_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, presence: true

  scope :upcoming, -> { pending.order(:recommended_age_days) }
  scope :completed, -> { administered.order(administered_at: :desc) }

  def recommended_date
    return nil unless baby&.date_of_birth && recommended_age_days
    baby.date_of_birth + recommended_age_days.days
  end

  def overdue?
    pending? && recommended_date.present? && recommended_date < Date.current
  end

  def due_soon?(days = 7)
    pending? && recommended_date.present? &&
      recommended_date >= Date.current &&
      recommended_date <= Date.current + days.days
  end
end
