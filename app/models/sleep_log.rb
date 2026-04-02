class SleepLog < ApplicationRecord
  belongs_to :baby
  belongs_to :user

  enum :sleep_type, { nap: "nap", night: "night" }

  LOCATIONS = %w[crib bassinet stroller car arms other].freeze

  validates :sleep_type, presence: true
  validates :location, inclusion: { in: LOCATIONS }, allow_nil: true

  scope :recent, -> { order(Arel.sql("COALESCE(started_at, created_at) DESC")) }
  scope :for_date, ->(date) {
    tz = Time.zone || ActiveSupport::TimeZone["America/New_York"]
    day_start = tz.parse(date.to_s).beginning_of_day
    day_end = tz.parse(date.to_s).end_of_day
    where("COALESCE(started_at, created_at) BETWEEN ? AND ?", day_start, day_end)
  }
  scope :in_range, ->(from, to) {
    tz = Time.zone || ActiveSupport::TimeZone["America/New_York"]
    where("COALESCE(started_at, created_at) BETWEEN ? AND ?",
      tz.parse(from.to_s).beginning_of_day, tz.parse(to.to_s).end_of_day)
  }

  before_save :compute_duration

  def display_time
    started_at || created_at
  end

  private

  def compute_duration
    if started_at.present? && ended_at.present?
      self.duration_minutes = ((ended_at - started_at) / 60).round
    end
  end
end
