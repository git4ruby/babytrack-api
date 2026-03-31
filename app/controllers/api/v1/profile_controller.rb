class Api::V1::ProfileController < ApplicationController
  # GET /api/v1/profile
  def show
    render json: {
      data: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        role: current_user.role,
        phone_number: current_user.phone_number,
      }
    }
  end

  # PATCH /api/v1/profile
  def update
    if current_user.update(profile_params)
      render json: {
        data: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name,
          phone_number: current_user.phone_number,
        }
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :phone_number)
  end
end
