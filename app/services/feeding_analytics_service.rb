class FeedingAnalyticsService
  TZ = "America/New_York"
  DATE_IN_TZ = "DATE(started_at AT TIME ZONE 'UTC' AT TIME ZONE '#{TZ}')"

  def initialize(baby, from_date, to_date)
    @baby = baby
    @from = from_date
    @to = to_date
  end

  def call
    {
      daily_totals: daily_totals,
      feed_type_breakdown: feed_type_breakdown,
      breast_balance: breast_balance,
      daily_feed_counts: daily_feed_counts,
      average_gap_by_day: average_gap_by_day,
    }
  end

  private

  def tz
    @tz ||= ActiveSupport::TimeZone[TZ]
  end

  def feedings
    @feedings ||= @baby.feedings.unscoped.kept.where(baby: @baby)
      .where(started_at: tz.parse(@from.to_s).beginning_of_day..tz.parse(@to.to_s).end_of_day)
      .reorder("")
  end

  def daily_totals
    feedings.where.not(volume_ml: nil)
      .group(Arel.sql(DATE_IN_TZ))
      .sum(:volume_ml)
      .transform_keys(&:to_s)
  end

  def feed_type_breakdown
    feedings.group(:feed_type).count
  end

  def breast_balance
    left = feedings.breastfeeds.where(breast_side: "left").sum(:duration_minutes)
    right = feedings.breastfeeds.where(breast_side: "right").sum(:duration_minutes)
    total = left + right
    return { left: 0, right: 0, left_percent: 0, right_percent: 0 } if total.zero?

    {
      left: left,
      right: right,
      left_percent: ((left.to_f / total) * 100).round(1),
      right_percent: ((right.to_f / total) * 100).round(1),
    }
  end

  def daily_feed_counts
    feedings.group(Arel.sql(DATE_IN_TZ)).count.transform_keys(&:to_s)
  end

  def average_gap_by_day
    result = {}
    rows = feedings.group(Arel.sql(DATE_IN_TZ))
      .pluck(Arel.sql(DATE_IN_TZ), Arel.sql("ARRAY_AGG(started_at ORDER BY started_at)"))

    rows.each do |date, times|
      next if times.size < 2
      gaps = times.each_cons(2).map { |a, b| (b - a) / 3600.0 }
      result[date.to_s] = (gaps.sum / gaps.size).round(2)
    end
    result
  end
end
