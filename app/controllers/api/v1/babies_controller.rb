class Api::V1::BabiesController < ApplicationController
  # GET /api/v1/babies
  def index
    babies = accessible_babies.order(:created_at)
    render json: {
      data: babies.map { |b| baby_json(b) }
    }
  end

  # GET /api/v1/baby (current baby)
  def show
    if current_baby
      render json: { data: baby_json(current_baby) }
    else
      render json: { data: nil }
    end
  end

  # POST /api/v1/babies
  def create
    baby = current_user.babies.build(baby_params)

    if baby.save
      render json: { data: baby_json(baby) }, status: :created
    else
      render json: { errors: baby.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/baby (update current baby)
  def update
    if current_baby.update(baby_params)
      render json: { data: baby_json(current_baby) }
    else
      render json: { errors: current_baby.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/babies/:id
  def update_baby
    baby = current_user.babies.find(params[:id])
    if baby.update(baby_params)
      render json: { data: baby_json(baby) }
    else
      render json: { errors: baby.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/babies/:id
  def destroy
    baby = current_user.babies.find(params[:id])

    if current_user.babies.count <= 1
      render json: { error: "Cannot delete your only baby. You must have at least one baby profile." }, status: :unprocessable_entity
      return
    end

    baby.destroy
    render json: { message: "Baby profile deleted" }
  end

  private

  def baby_params
    params.require(:baby).permit(:name, :date_of_birth, :gender, :birth_weight_grams, :birth_length_cm, :head_circumference_cm, :notes)
  end

  def baby_json(baby)
    {
      id: baby.id,
      name: baby.name,
      date_of_birth: baby.date_of_birth,
      gender: baby.gender,
      birth_weight_grams: baby.birth_weight_grams,
      birth_length_cm: baby.birth_length_cm,
      head_circumference_cm: baby.head_circumference_cm,
      age_in_days: baby.age_in_days,
      age_in_weeks: baby.age_in_weeks,
      notes: baby.notes
    }
  end
end
