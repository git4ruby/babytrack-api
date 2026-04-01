class Api::V1::AppointmentsController < ApplicationController
  before_action :set_appointment, only: [ :show, :update, :destroy ]

  # GET /api/v1/appointments
  def index
    appointments = current_baby.appointments.includes(:user).order(scheduled_at: :asc)

    appointments = appointments.where(status: params[:status]) if params[:status].present?

    render json: { data: appointments.map { |a| appointment_json(a) } }
  end

  # GET /api/v1/appointments/:id
  def show
    render json: { data: appointment_json(@appointment) }
  end

  # POST /api/v1/appointments
  def create
    appointment = current_baby.appointments.build(appointment_params)
    appointment.user = current_user

    if appointment.save
      render json: { data: appointment_json(appointment) }, status: :created
    else
      render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/appointments/:id
  def update
    if @appointment.update(appointment_params)
      render json: { data: appointment_json(@appointment) }
    else
      render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/appointments/:id
  def destroy
    @appointment.update(status: "cancelled")
    head :no_content
  end

  # GET /api/v1/appointments/next_upcoming
  def next_upcoming
    appointment = current_baby.appointments.future.first

    if appointment
      render json: { data: appointment_json(appointment) }
    else
      render json: { data: nil }
    end
  end

  private

  def set_appointment
    @appointment = current_baby.appointments.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(
      :title, :appointment_type, :scheduled_at, :location,
      :provider_name, :reminder_at, :status, :notes
    )
  end

  def appointment_json(appt)
    {
      id: appt.id,
      title: appt.title,
      appointment_type: appt.appointment_type,
      scheduled_at: appt.scheduled_at,
      location: appt.location,
      provider_name: appt.provider_name,
      reminder_at: appt.reminder_at,
      reminder_sent: appt.reminder_sent,
      status: appt.status,
      notes: appt.notes,
      created_at: appt.created_at,
      user: {
        id: appt.user.id,
        name: appt.user.name
      }
    }
  end
end
