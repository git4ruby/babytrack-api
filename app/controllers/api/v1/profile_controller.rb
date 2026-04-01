class Api::V1::ProfileController < ApplicationController
  # GET /api/v1/profile
  def show
    render json: {
      data: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        role: current_user.role,
        phone_number: current_user.phone_number
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
          phone_number: current_user.phone_number
        }
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/profile/password
  def change_password
    unless current_user.valid_password?(params[:current_password])
      render json: { errors: [ "Current password is incorrect" ] }, status: :unprocessable_entity
      return
    end

    if params[:new_password] != params[:new_password_confirmation]
      render json: { errors: [ "New passwords don't match" ] }, status: :unprocessable_entity
      return
    end

    if params[:new_password].length < 6
      render json: { errors: [ "New password must be at least 6 characters" ] }, status: :unprocessable_entity
      return
    end

    current_user.password = params[:new_password]
    if current_user.save
      render json: { message: "Password updated successfully" }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :phone_number)
  end
end
