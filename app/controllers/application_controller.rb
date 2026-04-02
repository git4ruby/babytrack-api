class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def current_baby
    @current_baby ||= if params[:baby_id].present?
      accessible_babies.find_by(id: params[:baby_id])
    else
      accessible_babies.first
    end
  end

  # All babies the user can access: owned + shared
  def accessible_babies
    owned_ids = current_user.babies.pluck(:id)
    shared_ids = current_user.baby_shares.accepted.pluck(:baby_id)
    Baby.where(id: owned_ids + shared_ids)
  end
end
