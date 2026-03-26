class Milestone < ApplicationRecord
  belongs_to :baby
  belongs_to :user

  CATEGORIES = %w[motor cognitive social language feeding sleep other].freeze

  validates :title, presence: true
  validates :achieved_on, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true

  scope :chronological, -> { order(achieved_on: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }

  def age_at_milestone
    return nil unless baby&.date_of_birth
    (achieved_on - baby.date_of_birth).to_i
  end
end
