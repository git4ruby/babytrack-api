class Api::V1::DiaryEntriesController < ApplicationController
  before_action :set_diary_entry, only: [ :show, :update, :destroy ]

  # GET /api/v1/diary_entries
  def index
    diary_entries = current_baby.diary_entries.includes(:user).chronological
    diary_entries = diary_entries.by_mood(params[:mood]) if params[:mood].present?

    render json: {
      data: diary_entries.map { |d| diary_entry_json(d) }
    }
  end

  # GET /api/v1/diary_entries/:id
  def show
    render json: { data: diary_entry_json(@diary_entry) }
  end

  # POST /api/v1/diary_entries
  def create
    diary_entry = current_baby.diary_entries.build(diary_entry_params)
    diary_entry.user = current_user

    if diary_entry.save
      render json: { data: diary_entry_json(diary_entry) }, status: :created
    else
      render json: { errors: diary_entry.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/diary_entries/:id
  def update
    if @diary_entry.update(diary_entry_params)
      render json: { data: diary_entry_json(@diary_entry) }
    else
      render json: { errors: @diary_entry.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/diary_entries/:id
  def destroy
    @diary_entry.destroy
    head :no_content
  end

  private

  def set_diary_entry
    @diary_entry = current_baby.diary_entries.find(params[:id])
  end

  def diary_entry_params
    params.require(:diary_entry).permit(:content, :entry_date, :mood, :photo_url)
  end

  def diary_entry_json(d)
    {
      id: d.id,
      content: d.content,
      entry_date: d.entry_date,
      mood: d.mood,
      age_days: d.age_at_entry,
      photo_url: d.photo_url,
      created_at: d.created_at,
      user: { id: d.user.id, name: d.user.name }
    }
  end
end
