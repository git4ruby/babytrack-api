class Api::V1::MilestonesController < ApplicationController
  before_action :set_milestone, only: [ :show, :update, :destroy ]

  # GET /api/v1/milestones
  def index
    milestones = current_baby.milestones.includes(:user).chronological
    milestones = milestones.by_category(params[:category]) if params[:category].present?

    render json: {
      data: milestones.map { |m| milestone_json(m) }
    }
  end

  # GET /api/v1/milestones/:id
  def show
    render json: { data: milestone_json(@milestone) }
  end

  # POST /api/v1/milestones
  def create
    milestone = current_baby.milestones.build(milestone_params)
    milestone.user = current_user

    if milestone.save
      render json: { data: milestone_json(milestone) }, status: :created
    else
      render json: { errors: milestone.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/milestones/:id
  def update
    if @milestone.update(milestone_params)
      render json: { data: milestone_json(@milestone) }
    else
      render json: { errors: @milestone.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/milestones/:id
  def destroy
    @milestone.destroy
    head :no_content
  end

  private

  def set_milestone
    @milestone = current_baby.milestones.find(params[:id])
  end

  def milestone_params
    params.require(:milestone).permit(:title, :description, :achieved_on, :category, :notes, :photo_url)
  end

  def milestone_json(m)
    {
      id: m.id,
      title: m.title,
      description: m.description,
      achieved_on: m.achieved_on,
      category: m.category,
      age_days: m.age_at_milestone,
      notes: m.notes,
      photo_url: m.photo_url,
      created_at: m.created_at,
      user: { id: m.user.id, name: m.user.name }
    }
  end
end
