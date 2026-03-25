class FeedingSummaryService
  def initialize(baby, date, range: "day")
    @baby = baby
    @date = date
    @range = range
  end

  def call
    {
      date: @date.to_s,
      range: @range,
      total_feeds: feedings.count,
      total_ml: total_ml,
      bottle_ml: bottle_ml,
      pump_ml: pump_ml,
      formula_ml: formula_ml,
      breast_milk_ml: breast_milk_ml,
      breast_duration_minutes: breast_duration_minutes,
      breast_balance: breast_balance,
      feeds_by_type: feeds_by_type,
      average_gap_hours: average_gap_hours,
      longest_gap_hours: longest_gap_hours
    }
  end

  private

  def feedings
    @feedings ||= case @range
    when "week"
      @baby.feedings.unscoped.kept.where(baby: @baby)
        .in_range(@date.beginning_of_week, @date.end_of_week)
        .chronological
    when "month"
      @baby.feedings.unscoped.kept.where(baby: @baby)
        .in_range(@date.beginning_of_month, @date.end_of_month)
        .chronological
    else
      @baby.feedings.unscoped.kept.where(baby: @baby)
        .for_date(@date)
        .chronological
    end
  end

  def total_ml
    feedings.where.not(volume_ml: nil).sum(:volume_ml)
  end

  def bottle_ml
    feedings.bottles.sum(:volume_ml)
  end

  def pump_ml
    feedings.pumps.sum(:volume_ml)
  end

  def formula_ml
    feedings.where(milk_type: "formula").sum(:volume_ml)
  end

  def breast_milk_ml
    feedings.where(milk_type: "breast_milk").where.not(volume_ml: nil).sum(:volume_ml)
  end

  def breast_duration_minutes
    {
      left: feedings.breastfeeds.where(breast_side: "left").sum(:duration_minutes),
      right: feedings.breastfeeds.where(breast_side: "right").sum(:duration_minutes),
      total: feedings.breastfeeds.sum(:duration_minutes)
    }
  end

  def breast_balance
    left = breast_duration_minutes[:left].to_f
    right = breast_duration_minutes[:right].to_f
    total = left + right
    return { left_percent: 0, right_percent: 0 } if total.zero?

    {
      left_percent: ((left / total) * 100).round(1),
      right_percent: ((right / total) * 100).round(1)
    }
  end

  def feeds_by_type
    {
      bottle: feedings.bottles.count,
      breastfeed: feedings.breastfeeds.count,
      pump: feedings.pumps.count
    }
  end

  def average_gap_hours
    gaps = compute_gaps
    return 0 if gaps.empty?

    (gaps.sum / gaps.size / 3600.0).round(2)
  end

  def longest_gap_hours
    gaps = compute_gaps
    return 0 if gaps.empty?

    (gaps.max / 3600.0).round(2)
  end

  def compute_gaps
    times = feedings.pluck(:started_at).sort
    return [] if times.size < 2

    times.each_cons(2).map { |a, b| (b - a).abs }
  end
end
