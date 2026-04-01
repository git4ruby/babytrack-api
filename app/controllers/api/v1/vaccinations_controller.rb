class Api::V1::VaccinationsController < ApplicationController
  before_action :set_vaccination, only: [ :show, :update, :administer ]

  # GET /api/v1/vaccinations
  def index
    vaccinations = current_baby.vaccinations.order(:recommended_age_days)

    vaccinations = vaccinations.where(status: params[:status]) if params[:status].present?

    render json: {
      data: vaccinations.map { |v| vaccination_json(v) },
      meta: {
        total: current_baby.vaccinations.count,
        administered: current_baby.vaccinations.administered.count,
        pending: current_baby.vaccinations.pending.count
      }
    }
  end

  # GET /api/v1/vaccinations/:id
  def show
    render json: { data: vaccination_json(@vaccination) }
  end

  # PATCH /api/v1/vaccinations/:id
  def update
    if @vaccination.update(vaccination_params)
      render json: { data: vaccination_json(@vaccination) }
    else
      render json: { errors: @vaccination.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/vaccinations/:id/administer
  def administer
    if @vaccination.update(
      status: "administered",
      administered_at: params[:administered_at] || Date.current,
      administered_by: params[:administered_by],
      lot_number: params[:lot_number],
      site: params[:site]
    )
      render json: { data: vaccination_json(@vaccination) }
    else
      render json: { errors: @vaccination.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/vaccinations/upcoming
  def upcoming
    vaccinations = current_baby.vaccinations.upcoming
      .select { |v| v.recommended_date && v.recommended_date <= Date.current + 30.days }

    render json: {
      data: vaccinations.map { |v| vaccination_json(v) }
    }
  end

  private

  def set_vaccination
    @vaccination = current_baby.vaccinations.find(params[:id])
  end

  def vaccination_params
    params.require(:vaccination).permit(
      :reactions, :lot_number, :site, :administered_by, :notes
    )
  end

  def vaccination_json(vax)
    {
      id: vax.id,
      vaccine_name: vax.vaccine_name,
      description: vax.description,
      recommended_age_days: vax.recommended_age_days,
      recommended_date: vax.recommended_date,
      administered_at: vax.administered_at,
      administered_by: vax.administered_by,
      lot_number: vax.lot_number,
      site: vax.site,
      reactions: vax.reactions,
      status: vax.status,
      overdue: vax.overdue?,
      due_soon: vax.due_soon?,
      created_at: vax.created_at
    }
  end
end
