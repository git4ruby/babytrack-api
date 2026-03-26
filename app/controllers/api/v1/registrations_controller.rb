class Api::V1::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        data: {
          id: resource.id,
          email: resource.email,
          name: resource.name,
          role: resource.role,
          phone_number: resource.phone_number
        },
        message: "Signed up successfully."
      }, status: :created
    else
      render json: {
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name)
  end

  def account_update_params
    params.require(:user).permit(:name, :phone_number)
  end
end
