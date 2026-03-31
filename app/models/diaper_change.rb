class DiaperChange < ApplicationRecord
  belongs_to :baby
  belongs_to :user

  enum :diaper_type, {
    wet: "wet",
    soiled: "soiled",
    both: "both",
    dry: "dry"
  }

  STOOL_COLORS = %w[yellow green brown black orange red].freeze
  CONSISTENCIES = %w[normal loose watery hard seedy mucousy].freeze

  validates :diaper_type, presence: true
  validates :stool_color, inclusion: { in: STOOL_COLORS }, allow_nil: true
  validates :consistency, inclusion: { in: CONSISTENCIES }, allow_nil: true

  scope :for_date, ->(date) {
    tz = Time.zone || ActiveSupport::TimeZone["America/New_York"]
    day_start = tz.parse(date.to_s).beginning_of_day
    day_end = tz.parse(date.to_s).end_of_day
    where("changed_at BETWEEN ? AND ? OR (changed_at IS NULL AND created_at BETWEEN ? AND ?)", day_start, day_end, day_start, day_end)
  }

  scope :in_range, ->(from, to) {
    tz = Time.zone || ActiveSupport::TimeZone["America/New_York"]
    from_t = tz.parse(from.to_s).beginning_of_day
    to_t = tz.parse(to.to_s).end_of_day
    where("changed_at BETWEEN ? AND ? OR (changed_at IS NULL AND created_at BETWEEN ? AND ?)", from_t, to_t, from_t, to_t)
  }

  scope :recent, -> { order(Arel.sql("COALESCE(changed_at, created_at) DESC")) }
  scope :wet_or_both, -> { where(diaper_type: %w[wet both]) }
  scope :soiled_or_both, -> { where(diaper_type: %w[soiled both]) }

  # Use changed_at if set, otherwise created_at
  def display_time
    changed_at || created_at
  end
end
