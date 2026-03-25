class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def current_baby
    @current_baby ||= Baby.first
  end
end
