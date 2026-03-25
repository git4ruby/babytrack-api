class WeightLog < ApplicationRecord
  belongs_to :baby
  belongs_to :user

  validates :recorded_at, presence: true
  validates :weight_grams, presence: true, numericality: { greater_than: 0 }
  validates :height_cm, numericality: { greater_than: 0 }, allow_nil: true
  validates :head_circumference_cm, numericality: { greater_than: 0 }, allow_nil: true

  scope :chronological, -> { order(recorded_at: :asc) }
  scope :recent, -> { order(recorded_at: :desc) }
end
