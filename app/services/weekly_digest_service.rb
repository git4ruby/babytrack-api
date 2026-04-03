class WeeklyDigestService
  TZ = "Eastern Time (US & Canada)"

  def initialize(baby, from_date, to_date)
    @baby = baby
    @from = from_date
    @to = to_date
  end

  def call
    {
      feeding: feeding_stats,
      diapers: diaper_stats,
      sleep: sleep_stats,
      milestones: milestone_stats,
      weight: weight_stats,
      upcoming_appointments: upcoming_appointments
    }
  end

  private

  def tz
    @tz ||= ActiveSupport::TimeZone[TZ]
  end

  def range_start
    @range_start ||= tz.parse(@from.to_s).beginning_of_day
  end

  def range_end
    @range_end ||= tz.parse(@to.to_s).end_of_day
  end

  # --- Feedings ---

  def feedings
    @feedings ||= @baby.feedings.where(started_at: range_start..range_end)
  end

  def feeding_stats
    count = feedings.count
    total_volume = feedings.where.not(volume_ml: nil).sum(:volume_ml)
    days = (@to - @from).to_i + 1
    avg_daily = days.positive? ? (count.to_f / days).round(1) : 0

    {
      count: count,
      total_volume_ml: total_volume,
      avg_daily_feeds: avg_daily
    }
  end

  # --- Diapers ---

  def diaper_changes
    @diaper_changes ||= @baby.diaper_changes.in_range(@from, @to)
  end

  def diaper_stats
    total = diaper_changes.count
    by_type = diaper_changes.group(:diaper_type).count

    {
      total: total,
      wet: by_type.fetch("wet", 0) + by_type.fetch("both", 0),
      soiled: by_type.fetch("soiled", 0) + by_type.fetch("both", 0),
      dry: by_type.fetch("dry", 0)
    }
  end

  # --- Sleep ---

  def sleep_logs
    @sleep_logs ||= @baby.sleep_logs.in_range(@from, @to)
  end

  def sleep_stats
    total_minutes = sleep_logs.where.not(duration_minutes: nil).sum(:duration_minutes)
    total_hours = (total_minutes / 60.0).round(1)
    days = (@to - @from).to_i + 1
    avg_daily_hours = days.positive? ? (total_hours / days).round(1) : 0

    {
      total_hours: total_hours,
      avg_daily_hours: avg_daily_hours
    }
  end

  # --- Milestones ---

  def milestone_stats
    @baby.milestones.where(achieved_on: @from..@to).order(:achieved_on)
  end

  # --- Weight ---

  def weight_stats
    entries = @baby.weight_logs.where(recorded_at: range_start..range_end).chronological
    return { entries: [], change_grams: nil } if entries.empty?

    latest = entries.last
    previous = @baby.weight_logs.where("recorded_at < ?", range_start).recent.first

    change = previous ? latest.weight_grams - previous.weight_grams : nil

    {
      entries: entries,
      change_grams: change
    }
  end

  # --- Upcoming Appointments (next 7 days from end of range) ---

  def upcoming_appointments
    from_t = tz.parse(@to.to_s).end_of_day
    to_t = from_t + 7.days

    @baby.appointments.status_upcoming.where(scheduled_at: from_t..to_t).order(:scheduled_at)
  end
end
