class MilkInventoryService
  def initialize(baby)
    @baby = baby
  end

  def call
    {
      summary: summary,
      by_storage_type: by_storage_type,
      expiring_soon: expiring_soon,
      expired_count: expired_count,
      recent_activity: recent_activity
    }
  end

  private

  def available_stashes
    @available_stashes ||= @baby.milk_stashes.available
  end

  def summary
    {
      total_ml: available_stashes.sum(:remaining_ml),
      total_bags: available_stashes.count,
      oldest_stored_at: available_stashes.minimum(:stored_at),
      newest_stored_at: available_stashes.maximum(:stored_at)
    }
  end

  def by_storage_type
    {
      room_temp: storage_summary("room_temp"),
      fridge: storage_summary("fridge"),
      freezer: storage_summary("freezer")
    }
  end

  def storage_summary(type)
    stashes = available_stashes.where(storage_type: type)
    {
      total_ml: stashes.sum(:remaining_ml),
      count: stashes.count,
      oldest_stored_at: stashes.minimum(:stored_at),
      items: stashes.oldest_first.map do |s|
        {
          id: s.id,
          label: s.label,
          remaining_ml: s.remaining_ml,
          volume_ml: s.volume_ml,
          stored_at: s.stored_at,
          expires_at: s.expires_at,
          hours_until_expiry: s.hours_until_expiry,
          expired: s.expired?
        }
      end
    }
  end

  def expiring_soon
    # Items expiring within 6 hours
    stashes = available_stashes.expiring_soon(6)
    {
      count: stashes.count,
      total_ml: stashes.sum(:remaining_ml),
      items: stashes.oldest_first.map do |s|
        {
          id: s.id,
          label: s.label,
          storage_type: s.storage_type,
          remaining_ml: s.remaining_ml,
          expires_at: s.expires_at,
          hours_until_expiry: s.hours_until_expiry
        }
      end
    }
  end

  def expired_count
    @baby.milk_stashes.expired_stashes.count
  end

  def recent_activity
    MilkStashLog
      .joins(:milk_stash)
      .where(milk_stashes: { baby_id: @baby.id })
      .includes(:milk_stash, :user)
      .recent
      .limit(10)
      .map do |log|
        {
          action: log.action,
          volume_ml: log.volume_ml,
          reason: log.reason,
          stash_label: log.milk_stash&.label,
          storage_type: log.milk_stash&.storage_type,
          created_at: log.created_at,
          user_name: log.user.name
        }
      end
  end
end
