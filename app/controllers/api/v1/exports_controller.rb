require "csv"

class Api::V1::ExportsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authenticate_from_token!

  private

  def authenticate_from_token!
    if params[:token].present?
      request.headers["Authorization"] = "Bearer #{params[:token]}"
    end
    authenticate_user!
  end

  public
  # GET /api/v1/exports/feedings.csv
  def feedings
    feedings = current_baby.feedings.includes(:user).order(started_at: :desc)
    feedings = feedings.where(started_at: parse_from..parse_to) if params[:from].present?

    csv = CSV.generate(headers: true) do |row|
      row << [ "Date", "Time", "Type", "Volume (ml)", "Milk Type", "Formula Brand", "Breast Side", "Duration (min)", "Notes" ]
      feedings.each do |f|
        t = f.started_at.in_time_zone(tz)
        row << [ t.strftime("%Y-%m-%d"), t.strftime("%I:%M %p"), f.feed_type, f.volume_ml, f.milk_type, f.formula_brand, f.breast_side, f.duration_minutes, f.notes ]
      end
    end

    send_data csv, filename: "#{current_baby.name.parameterize}-feedings-#{Date.current}.csv", type: "text/csv"
  end

  # GET /api/v1/exports/diapers.csv
  def diapers
    changes = current_baby.diaper_changes.includes(:user).recent
    changes = changes.in_range(params[:from], params[:to]) if params[:from].present?

    csv = CSV.generate(headers: true) do |row|
      row << [ "Date", "Time", "Type", "Stool Color", "Consistency", "Rash", "Notes" ]
      changes.each do |c|
        t = c.display_time.in_time_zone(tz)
        row << [ t.strftime("%Y-%m-%d"), c.changed_at ? t.strftime("%I:%M %p") : "", c.diaper_type, c.stool_color, c.consistency, c.has_rash ? "Yes" : "No", c.notes ]
      end
    end

    send_data csv, filename: "#{current_baby.name.parameterize}-diapers-#{Date.current}.csv", type: "text/csv"
  end

  # GET /api/v1/exports/weight.csv
  def weight
    logs = current_baby.weight_logs.includes(:user).chronological
    logs = logs.where(recorded_at: Date.parse(params[:from])..Date.parse(params[:to])) if params[:from].present?

    csv = CSV.generate(headers: true) do |row|
      row << [ "Date", "Weight (g)", "Weight (kg)", "Height (cm)", "Head (cm)", "Measured By", "Notes" ]
      logs.each do |l|
        row << [ l.recorded_at, l.weight_grams, (l.weight_grams / 1000.0).round(2), l.height_cm, l.head_circumference_cm, l.measured_by, l.notes ]
      end
    end

    send_data csv, filename: "#{current_baby.name.parameterize}-weight-#{Date.current}.csv", type: "text/csv"
  end

  # GET /api/v1/exports/milestones.csv
  def milestones
    records = current_baby.milestones.chronological
    records = records.where(achieved_on: Date.parse(params[:from])..Date.parse(params[:to])) if params[:from].present?

    csv = CSV.generate(headers: true) do |row|
      row << [ "Date", "Title", "Category", "Age (days)", "Description", "Notes" ]
      records.each do |m|
        row << [ m.achieved_on, m.title, m.category, m.age_at_milestone, m.description, m.notes ]
      end
    end

    send_data csv, filename: "#{current_baby.name.parameterize}-milestones-#{Date.current}.csv", type: "text/csv"
  end

  # GET /api/v1/exports/all.csv — combined summary
  def all
    csv = CSV.generate(headers: true) do |row|
      row << [ "Date", "Time", "Category", "Details", "Notes" ]

      # Feedings
      current_baby.feedings.order(started_at: :desc).each do |f|
        t = f.started_at.in_time_zone(tz)
        detail = "#{f.feed_type}: #{f.volume_ml}ml #{f.milk_type}" if f.volume_ml
        detail ||= "#{f.feed_type}: #{f.breast_side} #{f.duration_minutes}min"
        row << [ t.strftime("%Y-%m-%d"), t.strftime("%I:%M %p"), "Feeding", detail, f.notes ]
      end

      # Diapers
      current_baby.diaper_changes.recent.each do |c|
        t = c.display_time.in_time_zone(tz)
        detail = c.diaper_type
        detail += " #{c.stool_color}" if c.stool_color
        row << [ t.strftime("%Y-%m-%d"), c.changed_at ? t.strftime("%I:%M %p") : "", "Diaper", detail, c.notes ]
      end

      # Weight
      current_baby.weight_logs.chronological.each do |l|
        row << [ l.recorded_at, "", "Weight", "#{l.weight_grams}g (#{(l.weight_grams / 1000.0).round(2)}kg)", l.notes ]
      end

      # Milestones
      current_baby.milestones.chronological.each do |m|
        row << [ m.achieved_on, "", "Milestone", "#{m.title} (#{m.category})", m.description ]
      end
    end

    send_data csv, filename: "#{current_baby.name.parameterize}-all-data-#{Date.current}.csv", type: "text/csv"
  end

  private

  def tz
    @tz ||= ActiveSupport::TimeZone["America/New_York"]
  end

  def parse_from
    tz.parse(params[:from]).beginning_of_day
  end

  def parse_to
    tz.parse(params[:to] || Date.current.to_s).end_of_day
  end
end
