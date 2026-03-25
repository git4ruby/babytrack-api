class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def current_baby
    @current_baby ||= if params[:baby_id].present?
      current_user.babies.find(params[:baby_id])
    else
      current_user.babies.first
    end
  end
end
