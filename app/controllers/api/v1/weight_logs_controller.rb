class Api::V1::WeightLogsController < ApplicationController
  before_action :set_weight_log, only: [ :show, :update, :destroy ]

  # GET /api/v1/weight_logs
  def index
    logs = current_baby.weight_logs.includes(:user).chronological

    logs = logs.where("recorded_at >= ?", params[:from]) if params[:from].present?
    logs = logs.where("recorded_at <= ?", params[:to]) if params[:to].present?

    render json: { data: logs.map { |l| weight_log_json(l) } }
  end

  # GET /api/v1/weight_logs/:id
  def show
    render json: { data: weight_log_json(@weight_log) }
  end

  # POST /api/v1/weight_logs
  def create
    log = current_baby.weight_logs.build(weight_log_params)
    log.user = current_user

    if log.save
      render json: { data: weight_log_json(log) }, status: :created
    else
      render json: { errors: log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/weight_logs/:id
  def update
    if @weight_log.update(weight_log_params)
      render json: { data: weight_log_json(@weight_log) }
    else
      render json: { errors: @weight_log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/weight_logs/:id
  def destroy
    @weight_log.destroy
    head :no_content
  end

  # GET /api/v1/weight_logs/percentiles
  def percentiles
    service = WhoPercentileService.new(current_baby.gender)
    max_days = [ current_baby.age_in_days + 30, 365 ].min
    curves = service.weight_for_age_curves(max_days)

    logs = current_baby.weight_logs.chronological.map do |l|
      age = (l.recorded_at - current_baby.date_of_birth).to_i
      {
        recorded_at: l.recorded_at,
        weight_grams: l.weight_grams,
        age_days: age,
        percentile: service.percentile_for(age, l.weight_grams)
      }
    end

    render json: {
      data: {
        measurements: logs,
        curves: curves,
        gender: current_baby.gender
      }
    }
  end

  private

  def set_weight_log
    @weight_log = current_baby.weight_logs.find(params[:id])
  end

  def weight_log_params
    params.require(:weight_log).permit(
      :recorded_at, :weight_grams, :height_cm,
      :head_circumference_cm, :measured_by, :notes
    )
  end

  def weight_log_json(log)
    {
      id: log.id,
      recorded_at: log.recorded_at,
      weight_grams: log.weight_grams,
      height_cm: log.height_cm,
      head_circumference_cm: log.head_circumference_cm,
      measured_by: log.measured_by,
      notes: log.notes,
      created_at: log.created_at,
      user: {
        id: log.user.id,
        name: log.user.name
      }
    }
  end
end
