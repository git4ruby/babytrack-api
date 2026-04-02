class Api::V1::AdminController < ApplicationController
  before_action :require_admin!

  # GET /api/v1/admin/users
  def users
    users = User.order(:created_at).map do |u|
      {
        id: u.id,
        name: u.name,
        email: u.email,
        role: u.role,
        sms_enabled: u.sms_enabled,
        telegram_linked: u.telegram_chat_id.present?,
        babies_count: u.babies.count,
        created_at: u.created_at
      }
    end
    render json: { data: users }
  end

  # PATCH /api/v1/admin/users/:id
  def update_user
    user = User.find(params[:id])
    if user.update(admin_user_params)
      render json: { data: { id: user.id, name: user.name, email: user.email, sms_enabled: user.sms_enabled, role: user.role } }
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/admin/users/:id
  def destroy_user
    user = User.find(params[:id])
    if user.id == current_user.id
      render json: { error: "Cannot delete your own account" }, status: :unprocessable_entity
      return
    end
    user.babies.destroy_all
    user.destroy
    render json: { message: "User deleted" }
  end

  # GET /api/v1/admin/stats
  def stats
    render json: {
      data: {
        total_users: User.count,
        total_babies: Baby.count,
        total_feedings: Feeding.unscoped.count,
        total_diapers: DiaperChange.count,
        total_sleep_logs: SleepLog.count,
        sms_enabled_users: User.where(sms_enabled: true).count,
        telegram_users: User.where.not(telegram_chat_id: nil).count
      }
    }
  end

  private

  def require_admin!
    unless current_user.role == "parent" && current_user.id == 1
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end

  def admin_user_params
    params.require(:user).permit(:sms_enabled)
  end
end
