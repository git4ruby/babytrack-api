class Api::V1::BabiesController < ApplicationController
  # GET /api/v1/baby
  def show
    baby = current_baby
    render json: {
      data: {
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
    }
  end

  # PATCH /api/v1/baby
  def update
    if current_baby.update(baby_params)
      render json: { data: current_baby.as_json(only: [:id, :name, :date_of_birth, :gender, :birth_weight_grams, :notes]) }
    else
      render json: { errors: current_baby.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def baby_params
    params.require(:baby).permit(:name, :date_of_birth, :gender, :birth_weight_grams, :birth_length_cm, :head_circumference_cm, :notes)
  end
end
