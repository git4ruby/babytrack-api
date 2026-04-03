class Api::V1::ReportsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authenticate_from_token!

  def doctor_visit
    days = (params[:days] || 30).to_i
    pdf = DoctorReportService.new(current_baby, days).generate
    send_data pdf, filename: "#{current_baby.name.parameterize}-health-report.pdf", type: "application/pdf", disposition: "inline"
  end

  private

  def authenticate_from_token!
    if params[:token].present?
      request.headers["Authorization"] = "Bearer #{params[:token]}"
    end
    authenticate_user!
  end
end
