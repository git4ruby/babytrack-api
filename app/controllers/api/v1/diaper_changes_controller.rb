class Api::V1::DiaperChangesController < ApplicationController
  before_action :set_diaper_change, only: [ :show, :update, :destroy ]

  # GET /api/v1/diaper_changes
  def index
    changes = current_baby.diaper_changes.includes(:user).recent

    if params[:from].present? && params[:to].present?
      changes = changes.in_range(params[:from], params[:to])
    elsif params[:date].present?
      changes = changes.for_date(Date.parse(params[:date]))
    end

    changes = changes.where(diaper_type: params[:diaper_type]) if params[:diaper_type].present?
    changes = changes.page(params[:page]).per(params[:per_page] || 50)

    render json: {
      data: changes.map { |c| change_json(c) },
      meta: {
        current_page: changes.current_page,
        total_pages: changes.total_pages,
        total_count: changes.total_count
      }
    }
  end

  # GET /api/v1/diaper_changes/:id
  def show
    render json: { data: change_json(@diaper_change) }
  end

  # POST /api/v1/diaper_changes
  def create
    change = current_baby.diaper_changes.build(change_params)
    change.user = current_user

    if change.save
      render json: { data: change_json(change) }, status: :created
    else
      render json: { errors: change.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/diaper_changes/:id
  def update
    if @diaper_change.update(change_params)
      render json: { data: change_json(@diaper_change) }
    else
      render json: { errors: @diaper_change.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/diaper_changes/:id
  def destroy
    @diaper_change.destroy
    head :no_content
  end

  # GET /api/v1/diaper_changes/summary?date=YYYY-MM-DD
  def summary
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    changes = current_baby.diaper_changes.for_date(date)

    render json: {
      data: {
        date: date.to_s,
        total: changes.count,
        wet: changes.wet.count + changes.both.count,
        soiled: changes.soiled.count + changes.both.count,
        dry: changes.dry.count,
        has_rash: changes.where(has_rash: true).count,
        by_type: {
          wet: changes.wet.count,
          soiled: changes.soiled.count,
          both: changes.both.count,
          dry: changes.dry.count
        }
      }
    }
  end

  # GET /api/v1/diaper_changes/stats?from=&to=
  def stats
    from_date = params[:from].present? ? Date.parse(params[:from]) : 7.days.ago.to_date
    to_date = params[:to].present? ? Date.parse(params[:to]) : Date.current

    tz = Time.zone
    changes = current_baby.diaper_changes.in_range(from_date, to_date)

    coalesce = "COALESCE(changed_at, created_at)"
    date_sql = "DATE(#{coalesce} AT TIME ZONE 'UTC' AT TIME ZONE '#{tz.tzinfo.name}')"

    daily_counts = changes.group(Arel.sql(date_sql)).count.transform_keys(&:to_s)
    daily_wet = changes.wet_or_both.group(Arel.sql(date_sql)).count.transform_keys(&:to_s)
    daily_soiled = changes.soiled_or_both.group(Arel.sql(date_sql)).count.transform_keys(&:to_s)

    total_days = (to_date - from_date).to_i + 1

    render json: {
      data: {
        from: from_date.to_s,
        to: to_date.to_s,
        total_changes: changes.count,
        total_wet: changes.wet_or_both.count,
        total_soiled: changes.soiled_or_both.count,
        avg_per_day: total_days > 0 ? (changes.count.to_f / total_days).round(1) : 0,
        rash_days: changes.where(has_rash: true).select(Arel.sql("DISTINCT #{date_sql}")).count,
        daily_counts: daily_counts,
        daily_wet: daily_wet,
        daily_soiled: daily_soiled
      }
    }
  end

  private

  def set_diaper_change
    @diaper_change = current_baby.diaper_changes.find(params[:id])
  end

  def change_params
    params.require(:diaper_change).permit(
      :changed_at, :diaper_type, :stool_color,
      :consistency, :has_rash, :notes
    )
  end

  def change_json(change)
    {
      id: change.id,
      changed_at: change.display_time,
      has_time: change.changed_at.present?,
      diaper_type: change.diaper_type,
      stool_color: change.stool_color,
      consistency: change.consistency,
      has_rash: change.has_rash,
      notes: change.notes,
      created_at: change.created_at,
      user: {
        id: change.user.id,
        name: change.user.name
      }
    }
  end
end
