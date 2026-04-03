class DoctorReportService
  BRAND_COLOR = "4A90D9"
  HEADER_BG = "EAF0FA"
  LIGHT_GRAY = "F5F5F5"

  def initialize(baby, days = 30)
    @baby = baby
    @days = days
    @start_date = days.days.ago.beginning_of_day
    @end_date = Time.current.end_of_day
  end

  def generate
    pdf = Prawn::Document.new(page_size: "LETTER", margin: [ 40, 40, 50, 40 ])
    register_fonts(pdf)

    render_header(pdf)
    render_baby_info(pdf)
    render_growth_section(pdf)
    render_feeding_summary(pdf)
    render_diaper_summary(pdf)
    render_sleep_summary(pdf)
    render_milestones(pdf)
    render_vaccinations(pdf)
    render_upcoming_appointments(pdf)
    render_footer(pdf)

    pdf.render
  end

  private

  def register_fonts(pdf)
    # Use Prawn's built-in Helvetica font family
    pdf.font "Helvetica"
  end

  # --- Header ---

  def render_header(pdf)
    pdf.fill_color BRAND_COLOR
    pdf.text "LullaTrack", size: 28, style: :bold
    pdf.fill_color "333333"
    pdf.text "Baby Health Report", size: 16, style: :bold
    pdf.move_down 4
    pdf.stroke_color BRAND_COLOR
    pdf.stroke_horizontal_rule
    pdf.move_down 12
  end

  # --- Baby Info ---

  def render_baby_info(pdf)
    age_str = format_age(@baby.age_in_days)
    gender_str = @baby.gender.present? ? @baby.gender.capitalize : "Not specified"
    period_str = "#{@start_date.strftime('%b %d, %Y')} - #{@end_date.strftime('%b %d, %Y')}"

    data = [
      [ "Name", sanitize_text(@baby.name) ],
      [ "Date of Birth", @baby.date_of_birth.strftime("%B %d, %Y") ],
      [ "Age", age_str ],
      [ "Gender", gender_str ],
      [ "Report Period", period_str ]
    ]

    pdf.table(data, width: pdf.bounds.width, cell_style: { borders: [], padding: [ 4, 8 ] }) do |t|
      t.columns(0).font_style = :bold
      t.columns(0).width = 120
    end
    pdf.move_down 16
  end

  # --- Growth ---

  def render_growth_section(pdf)
    section_heading(pdf, "Growth")

    latest = @baby.weight_logs.recent.first
    unless latest
      pdf.text "No growth data recorded.", size: 10, color: "999999"
      pdf.move_down 12
      return
    end

    rows = [ [ "Measurement", "Value", "WHO Percentile" ] ]

    if latest.weight_grams.present?
      percentile = weight_percentile(latest)
      rows << [
        "Weight",
        format_weight(latest.weight_grams),
        percentile ? "#{percentile}th" : "N/A"
      ]
    end

    if latest.height_cm.present?
      rows << [ "Height", "#{latest.height_cm} cm", "N/A" ]
    end

    if latest.head_circumference_cm.present?
      rows << [ "Head Circumference", "#{latest.head_circumference_cm} cm", "N/A" ]
    end

    rows << [ "Recorded On", latest.recorded_at.strftime("%b %d, %Y"), "" ]

    pdf.table(rows, width: pdf.bounds.width, cell_style: { size: 10, padding: [ 5, 8 ] }) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = HEADER_BG
      t.cells.borders = [ :bottom ]
      t.cells.border_color = "DDDDDD"
    end
    pdf.move_down 12
  end

  # --- Feeding Summary ---

  def render_feeding_summary(pdf)
    section_heading(pdf, "Feeding Summary")

    feedings = @baby.feedings.where(started_at: @start_date..@end_date)

    if feedings.empty?
      pdf.text "No feeding data in this period.", size: 10, color: "999999"
      pdf.move_down 12
      return
    end

    num_days = [ (@end_date.to_date - @start_date.to_date).to_i, 1 ].max
    total_feeds = feedings.count
    total_volume = feedings.where.not(volume_ml: nil).sum(:volume_ml)
    avg_daily = (total_feeds.to_f / num_days).round(1)

    rows = [ [ "Metric", "Value" ] ]
    rows << [ "Total Feeds", total_feeds.to_s ]
    rows << [ "Avg Daily Feeds", avg_daily.to_s ]
    rows << [ "Total Volume", "#{total_volume} ml" ]

    # Breakdown by type
    Feeding.feed_types.each_key do |ft|
      count = feedings.where(feed_type: ft).count
      rows << [ "  #{ft.capitalize}", count.to_s ] if count > 0
    end

    pdf.table(rows, width: pdf.bounds.width * 0.6, cell_style: { size: 10, padding: [ 5, 8 ] }) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = HEADER_BG
      t.cells.borders = [ :bottom ]
      t.cells.border_color = "DDDDDD"
    end
    pdf.move_down 12
  end

  # --- Diaper Summary ---

  def render_diaper_summary(pdf)
    section_heading(pdf, "Diaper Summary")

    diapers = @baby.diaper_changes.in_range(@start_date, @end_date)

    if diapers.empty?
      pdf.text "No diaper data in this period.", size: 10, color: "999999"
      pdf.move_down 12
      return
    end

    num_days = [ (@end_date.to_date - @start_date.to_date).to_i, 1 ].max
    total = diapers.count
    avg_daily = (total.to_f / num_days).round(1)

    rows = [ [ "Metric", "Value" ] ]
    rows << [ "Total Changes", total.to_s ]
    rows << [ "Avg Daily", avg_daily.to_s ]

    DiaperChange.diaper_types.each_key do |dt|
      count = diapers.where(diaper_type: dt).count
      rows << [ "  #{dt.capitalize}", count.to_s ] if count > 0
    end

    pdf.table(rows, width: pdf.bounds.width * 0.6, cell_style: { size: 10, padding: [ 5, 8 ] }) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = HEADER_BG
      t.cells.borders = [ :bottom ]
      t.cells.border_color = "DDDDDD"
    end
    pdf.move_down 12
  end

  # --- Sleep Summary ---

  def render_sleep_summary(pdf)
    section_heading(pdf, "Sleep Summary")

    sleeps = @baby.sleep_logs.in_range(@start_date, @end_date)

    if sleeps.empty?
      pdf.text "No sleep data in this period.", size: 10, color: "999999"
      pdf.move_down 12
      return
    end

    num_days = [ (@end_date.to_date - @start_date.to_date).to_i, 1 ].max
    total_minutes = sleeps.where.not(duration_minutes: nil).sum(:duration_minutes)
    avg_daily_hours = (total_minutes.to_f / num_days / 60).round(1)

    nap_minutes = sleeps.where(sleep_type: "nap").where.not(duration_minutes: nil).sum(:duration_minutes)
    night_minutes = sleeps.where(sleep_type: "night").where.not(duration_minutes: nil).sum(:duration_minutes)

    rows = [ [ "Metric", "Value" ] ]
    rows << [ "Avg Daily Sleep", "#{avg_daily_hours} hours" ]
    rows << [ "Total Nap Time", format_duration(nap_minutes) ]
    rows << [ "Total Night Sleep", format_duration(night_minutes) ]
    rows << [ "Nap Sessions", sleeps.where(sleep_type: "nap").count.to_s ]
    rows << [ "Night Sessions", sleeps.where(sleep_type: "night").count.to_s ]

    pdf.table(rows, width: pdf.bounds.width * 0.6, cell_style: { size: 10, padding: [ 5, 8 ] }) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = HEADER_BG
      t.cells.borders = [ :bottom ]
      t.cells.border_color = "DDDDDD"
    end
    pdf.move_down 12
  end

  # --- Milestones ---

  def render_milestones(pdf)
    section_heading(pdf, "Milestones Achieved")

    milestones = @baby.milestones
      .where(achieved_on: @start_date.to_date..@end_date.to_date)
      .order(achieved_on: :desc)

    if milestones.empty?
      pdf.text "No milestones recorded in this period.", size: 10, color: "999999"
      pdf.move_down 12
      return
    end

    rows = [ [ "Date", "Milestone", "Category" ] ]
    milestones.each do |m|
      rows << [
        m.achieved_on.strftime("%b %d, %Y"),
        sanitize_text(m.title),
        m.category&.capitalize || "N/A"
      ]
    end

    pdf.table(rows, width: pdf.bounds.width, cell_style: { size: 10, padding: [ 5, 8 ] }) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = HEADER_BG
      t.cells.borders = [ :bottom ]
      t.cells.border_color = "DDDDDD"
    end
    pdf.move_down 12
  end

  # --- Vaccinations ---

  def render_vaccinations(pdf)
    section_heading(pdf, "Vaccinations")

    administered = @baby.vaccinations.administered.order(administered_at: :desc).limit(20)
    upcoming = @baby.vaccinations.pending.order(:recommended_age_days).limit(10)

    if administered.empty? && upcoming.empty?
      pdf.text "No vaccination data recorded.", size: 10, color: "999999"
      pdf.move_down 12
      return
    end

    if administered.any?
      pdf.text "Administered", size: 11, style: :bold
      pdf.move_down 4

      rows = [ [ "Vaccine", "Date" ] ]
      administered.each do |v|
        rows << [
          sanitize_text(v.vaccine_name),
          v.administered_at&.strftime("%b %d, %Y") || "N/A"
        ]
      end

      pdf.table(rows, width: pdf.bounds.width * 0.7, cell_style: { size: 10, padding: [ 4, 8 ] }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = HEADER_BG
        t.cells.borders = [ :bottom ]
        t.cells.border_color = "DDDDDD"
      end
      pdf.move_down 8
    end

    if upcoming.any?
      pdf.text "Upcoming / Pending", size: 11, style: :bold
      pdf.move_down 4

      rows = [ [ "Vaccine", "Recommended Date", "Status" ] ]
      upcoming.each do |v|
        status = v.overdue? ? "OVERDUE" : "Pending"
        rows << [
          sanitize_text(v.vaccine_name),
          v.recommended_date&.strftime("%b %d, %Y") || "N/A",
          status
        ]
      end

      pdf.table(rows, width: pdf.bounds.width * 0.85, cell_style: { size: 10, padding: [ 4, 8 ] }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = HEADER_BG
        t.cells.borders = [ :bottom ]
        t.cells.border_color = "DDDDDD"
      end
    end

    pdf.move_down 12
  end

  # --- Upcoming Appointments ---

  def render_upcoming_appointments(pdf)
    section_heading(pdf, "Upcoming Appointments")

    appointments = @baby.appointments.future.limit(10)

    if appointments.empty?
      pdf.text "No upcoming appointments.", size: 10, color: "999999"
      pdf.move_down 12
      return
    end

    rows = [ [ "Date", "Title", "Provider", "Location" ] ]
    appointments.each do |a|
      rows << [
        a.scheduled_at.strftime("%b %d, %Y %I:%M %p"),
        sanitize_text(a.title),
        sanitize_text(a.provider_name) || "N/A",
        sanitize_text(a.location) || "N/A"
      ]
    end

    pdf.table(rows, width: pdf.bounds.width, cell_style: { size: 10, padding: [ 4, 8 ] }) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = HEADER_BG
      t.cells.borders = [ :bottom ]
      t.cells.border_color = "DDDDDD"
    end
    pdf.move_down 12
  end

  # --- Footer ---

  def render_footer(pdf)
    pdf.move_down 8
    pdf.stroke_color "CCCCCC"
    pdf.stroke_horizontal_rule
    pdf.move_down 6
    pdf.fill_color "999999"
    pdf.text "Generated by LullaTrack on #{Time.current.strftime('%B %d, %Y at %I:%M %p')}", size: 8, align: :center
    pdf.text "This report is for informational purposes only. Consult your pediatrician for medical advice.", size: 7, align: :center
    pdf.fill_color "333333"
  end

  # --- Helpers ---

  def section_heading(pdf, title)
    pdf.fill_color BRAND_COLOR
    pdf.text title, size: 14, style: :bold
    pdf.fill_color "333333"
    pdf.move_down 6
  end

  def format_age(days)
    if days < 30
      "#{days} days"
    elsif days < 365
      months = (days / 30.44).floor
      remaining_days = days - (months * 30.44).round
      "#{months} month#{'s' if months != 1}, #{remaining_days} day#{'s' if remaining_days != 1}"
    else
      years = (days / 365.25).floor
      remaining_months = ((days - years * 365.25) / 30.44).floor
      "#{years} year#{'s' if years != 1}, #{remaining_months} month#{'s' if remaining_months != 1}"
    end
  end

  def format_weight(grams)
    if grams >= 1000
      "#{(grams / 1000.0).round(2)} kg (#{grams} g)"
    else
      "#{grams} g"
    end
  end

  def format_duration(total_minutes)
    hours = total_minutes / 60
    mins = total_minutes % 60
    "#{hours}h #{mins}m"
  end

  def sanitize_text(str)
    return "" if str.blank?
    str.to_s.encode("Windows-1252", undef: :replace, invalid: :replace, replace: "")
  end

  def weight_percentile(weight_log)
    return nil unless @baby.gender.present? && weight_log.weight_grams.present?

    age_days = (@baby.date_of_birth && weight_log.recorded_at) ?
      (weight_log.recorded_at.to_date - @baby.date_of_birth).to_i : nil
    return nil unless age_days&.positive?

    WhoPercentileService.new(@baby.gender).percentile_for(age_days, weight_log.weight_grams)
  rescue StandardError
    nil
  end
end
