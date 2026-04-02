class Api::V1::SleepLogsController < ApplicationController
  before_action :set_sleep_log, only: [ :show, :update, :destroy ]

  # GET /api/v1/sleep_logs
  def index
    logs = current_baby.sleep_logs.includes(:user).recent

    if params[:from].present? && params[:to].present?
      logs = logs.in_range(params[:from], params[:to])
    elsif params[:date].present?
      logs = logs.for_date(Date.parse(params[:date]))
    end

    render json: { data: logs.map { |l| sleep_json(l) } }
  end

  # POST /api/v1/sleep_logs
  def create
    log = current_baby.sleep_logs.build(sleep_params)
    log.user = current_user

    if log.save
      render json: { data: sleep_json(log) }, status: :created
    else
      render json: { errors: log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/sleep_logs/:id
  def update
    if @sleep_log.update(sleep_params)
      render json: { data: sleep_json(@sleep_log) }
    else
      render json: { errors: @sleep_log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/sleep_logs/:id
  def destroy
    @sleep_log.destroy
    head :no_content
  end

  # GET /api/v1/sleep_logs/summary?date=
  def summary
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    logs = current_baby.sleep_logs.for_date(date)

    total_minutes = logs.sum(:duration_minutes)
    nap_minutes = logs.nap.sum(:duration_minutes)
    night_minutes = logs.night.sum(:duration_minutes)

    render json: {
      data: {
        date: date.to_s,
        total_sleep_minutes: total_minutes,
        total_sleep_hours: (total_minutes / 60.0).round(1),
        nap_count: logs.nap.count,
        nap_minutes: nap_minutes,
        night_minutes: night_minutes,
        sessions: logs.count
      }
    }
  end

  private

  def set_sleep_log
    @sleep_log = current_baby.sleep_logs.find(params[:id])
  end

  def sleep_params
    params.require(:sleep_log).permit(:started_at, :ended_at, :sleep_type, :location, :notes)
  end

  def sleep_json(log)
    {
      id: log.id,
      started_at: log.started_at,
      ended_at: log.ended_at,
      duration_minutes: log.duration_minutes,
      sleep_type: log.sleep_type,
      location: log.location,
      notes: log.notes,
      created_at: log.created_at,
      user: { id: log.user.id, name: log.user.name }
    }
  end
end
