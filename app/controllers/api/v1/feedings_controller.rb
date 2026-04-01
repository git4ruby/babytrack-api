class Api::V1::FeedingsController < ApplicationController
  before_action :set_feeding, only: [ :show, :update, :destroy ]

  # GET /api/v1/feedings
  def index
    feedings = current_baby.feedings.includes(:user).recent

    if params[:from].present? && params[:to].present?
      tz = Time.zone
      from_time = tz.parse(params[:from]).beginning_of_day
      to_time = tz.parse(params[:to]).end_of_day
      feedings = feedings.where(started_at: from_time..to_time)
    elsif params[:date].present?
      feedings = feedings.for_date(Date.parse(params[:date]))
    end
    feedings = feedings.where(feed_type: params[:feed_type]) if params[:feed_type].present?

    feedings = feedings.page(params[:page]).per(params[:per_page] || 50)

    render json: {
      data: feedings.map { |f| feeding_json(f) },
      meta: {
        current_page: feedings.current_page,
        total_pages: feedings.total_pages,
        total_count: feedings.total_count
      }
    }
  end

  # GET /api/v1/feedings/:id
  def show
    render json: { data: feeding_json(@feeding) }
  end

  # POST /api/v1/feedings
  def create
    feeding = current_baby.feedings.build(feeding_params)
    feeding.user = current_user

    if feeding.save
      render json: { data: feeding_json(feeding) }, status: :created
    else
      render json: { errors: feeding.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/feedings/:id
  def update
    if @feeding.update(feeding_params)
      render json: { data: feeding_json(@feeding) }
    else
      render json: { errors: @feeding.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/feedings/:id (soft-delete)
  def destroy
    @feeding.discard
    head :no_content
  end

  # GET /api/v1/feedings/summary?date=YYYY-MM-DD
  def summary
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    range = params[:range] || "day"

    result = FeedingSummaryService.new(current_baby, date, range: range).call
    render json: { data: result }
  end

  # GET /api/v1/feedings/analytics?from=YYYY-MM-DD&to=YYYY-MM-DD
  def analytics
    from_date = params[:from].present? ? Date.parse(params[:from]) : 7.days.ago.to_date
    to_date = params[:to].present? ? Date.parse(params[:to]) : Date.current

    result = FeedingAnalyticsService.new(current_baby, from_date, to_date).call
    render json: { data: result }
  end

  # GET /api/v1/feedings/last
  def last
    feeding = current_baby.feedings.recent.first

    if feeding
      render json: { data: feeding_json(feeding) }
    else
      render json: { data: nil }
    end
  end

  private

  def set_feeding
    @feeding = current_baby.feedings.find(params[:id])
  end

  def feeding_params
    params.require(:feeding).permit(
      :feed_type, :started_at, :ended_at, :duration_minutes,
      :volume_ml, :breast_side, :milk_type, :formula_brand,
      :notes, :session_group
    )
  end

  def feeding_json(feeding)
    {
      id: feeding.id,
      feed_type: feeding.feed_type,
      started_at: feeding.started_at,
      ended_at: feeding.ended_at,
      duration_minutes: feeding.duration_minutes,
      volume_ml: feeding.volume_ml,
      breast_side: feeding.breast_side,
      milk_type: feeding.milk_type,
      formula_brand: feeding.formula_brand,
      notes: feeding.notes,
      session_group: feeding.session_group,
      created_at: feeding.created_at,
      user: {
        id: feeding.user.id,
        name: feeding.user.name
      }
    }
  end
end
