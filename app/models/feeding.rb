class Feeding < ApplicationRecord
  include Discard::Model

  belongs_to :baby
  belongs_to :user

  enum :feed_type, { bottle: "bottle", breastfeed: "breastfeed", pump: "pump" }
  enum :milk_type, { breast_milk: "breast_milk", formula: "formula", mixed: "mixed" }, prefix: true

  validates :feed_type, presence: true
  validates :started_at, presence: true
  validates :volume_ml, numericality: { greater_than: 0 }, allow_nil: true
  validates :breast_side, inclusion: { in: %w[left right both] }, allow_nil: true
  validate :validate_feed_type_fields

  scope :for_date, ->(date) {
    tz = Time.zone || ActiveSupport::TimeZone["America/New_York"]
    day_start = tz.parse(date.to_s).beginning_of_day
    day_end = tz.parse(date.to_s).end_of_day
    where(started_at: day_start..day_end)
  }
  scope :in_range, ->(from, to) { where(started_at: from..to) }
  scope :recent, -> { order(started_at: :desc) }
  scope :chronological, -> { order(started_at: :asc) }
  scope :bottles, -> { where(feed_type: "bottle") }
  scope :breastfeeds, -> { where(feed_type: "breastfeed") }
  scope :pumps, -> { where(feed_type: "pump") }

  default_scope -> { kept }

  before_save :compute_duration

  private

  def compute_duration
    if started_at.present? && ended_at.present?
      self.duration_minutes = ((ended_at - started_at) / 60).round
    end
  end

  def validate_feed_type_fields
    if bottle? || pump?
      errors.add(:volume_ml, "is required for bottle/pump feeds") if volume_ml.blank?
    end

    if breastfeed?
      errors.add(:breast_side, "is required for breastfeed") if breast_side.blank?
    end
  end
end
