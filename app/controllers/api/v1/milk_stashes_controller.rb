class Api::V1::MilkStashesController < ApplicationController
  before_action :set_stash, only: [ :show, :update, :destroy, :consume, :discard, :transfer ]

  # GET /api/v1/milk_stashes
  def index
    stashes = current_baby.milk_stashes.newest_first

    stashes = stashes.where(storage_type: params[:storage_type]) if params[:storage_type].present?
    stashes = stashes.where(status: params[:status]) if params[:status].present?

    # Default: only show available (in-stock) stashes unless status filter is given
    stashes = stashes.available unless params[:status].present? || params[:all] == "true"

    render json: {
      data: stashes.map { |s| stash_json(s) }
    }
  end

  # GET /api/v1/milk_stashes/inventory
  def inventory
    render json: { data: MilkInventoryService.new(current_baby).call }
  end

  # GET /api/v1/milk_stashes/:id
  def show
    logs = @stash.milk_stash_logs.includes(:user).order(created_at: :desc)
    render json: {
      data: stash_json(@stash),
      logs: logs.map { |l| log_json(l) }
    }
  end

  # POST /api/v1/milk_stashes
  def create
    stash = current_baby.milk_stashes.build(stash_params)
    stash.user = current_user

    if stash.save
      render json: { data: stash_json(stash) }, status: :created
    else
      render json: { errors: stash.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/milk_stashes/:id
  def update
    if @stash.update(stash_update_params)
      render json: { data: stash_json(@stash) }
    else
      render json: { errors: @stash.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/milk_stashes/:id
  def destroy
    @stash.destroy
    head :no_content
  end

  # POST /api/v1/milk_stashes/:id/consume
  # Params: volume_ml (required), feeding_id (optional), notes (optional)
  def consume
    volume = params[:volume_ml].to_i
    feeding = params[:feeding_id].present? ? Feeding.find(params[:feeding_id]) : nil

    @stash.consume!(
      volume: volume,
      user: current_user,
      feeding: feeding,
      notes: params[:notes]
    )

    render json: { data: stash_json(@stash.reload) }
  rescue RuntimeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/milk_stashes/:id/discard
  # Params: volume_ml (required), reason (optional: expired/spilled/contaminated/other), notes (optional)
  def discard
    volume = params[:volume_ml].to_i

    @stash.discard!(
      volume: volume,
      user: current_user,
      reason: params[:reason],
      notes: params[:notes]
    )

    render json: { data: stash_json(@stash.reload) }
  rescue RuntimeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/milk_stashes/:id/transfer
  # Params: destination (required: fridge/freezer), notes (optional)
  def transfer
    @stash.transfer!(
      user: current_user,
      destination: params[:destination],
      notes: params[:notes]
    )

    render json: { data: stash_json(@stash.reload) }
  rescue RuntimeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/milk_stashes/history
  def history
    stash_ids = current_baby.milk_stashes.pluck(:id)
    logs = MilkStashLog
      .where(milk_stash_id: stash_ids)
      .order(created_at: :desc)

    logs = logs.where(action: params[:log_action]) if params[:log_action].present?
    logs = logs.limit(params[:limit] || 50)

    loaded = logs.to_a
    render json: {
      data: loaded.map { |l|
        {
          id: l.id,
          log_action: l.action,
          volume_ml: l.volume_ml,
          destination_storage_type: l.destination_storage_type,
          feeding_id: l.feeding_id,
          reason: l.reason,
          notes: l.notes,
          created_at: l.created_at,
          stash_label: l.milk_stash&.label,
          stash_storage_type: l.milk_stash&.storage_type,
          user: {
            id: l.user.id,
            name: l.user.name
          }
        }
      }
    }
  end

  private

  def set_stash
    @stash = current_baby.milk_stashes.find(params[:id])
  end

  def stash_params
    params.require(:milk_stash).permit(
      :volume_ml, :storage_type, :source_type,
      :label, :stored_at, :notes
    )
  end

  def stash_update_params
    params.require(:milk_stash).permit(:label, :notes, :volume_ml, :remaining_ml, :storage_type, :stored_at)
  end

  def stash_json(stash)
    {
      id: stash.id,
      volume_ml: stash.volume_ml,
      remaining_ml: stash.remaining_ml,
      storage_type: stash.storage_type,
      status: stash.status,
      source_type: stash.source_type,
      label: stash.label,
      stored_at: stash.stored_at,
      expires_at: stash.expires_at,
      thawed_at: stash.thawed_at,
      expired: stash.expired?,
      hours_until_expiry: stash.hours_until_expiry,
      notes: stash.notes,
      created_at: stash.created_at,
      user: {
        id: stash.user.id,
        name: stash.user.name
      }
    }
  end

  def log_json(log)
    {
      id: log.id,
      log_action: log.action,
      volume_ml: log.volume_ml,
      destination_storage_type: log.destination_storage_type,
      feeding_id: log.feeding_id,
      reason: log.reason,
      notes: log.notes,
      created_at: log.created_at,
      stash_label: log.milk_stash&.label,
      stash_storage_type: log.milk_stash&.storage_type,
      user: {
        id: log.user.id,
        name: log.user.name
      }
    }
  end
end
