class MilkStash < ApplicationRecord
  belongs_to :baby
  belongs_to :user
  has_many :milk_stash_logs, dependent: :destroy

  enum :storage_type, {
    room_temp: "room_temp",
    fridge: "fridge",
    freezer: "freezer"
  }

  enum :status, {
    available: "available",
    consumed: "consumed",
    discarded: "discarded",
    expired: "expired"
  }

  enum :source_type, {
    pumped: "pumped",
    donated: "donated"
  }, prefix: true

  validates :volume_ml, presence: true, numericality: { greater_than: 0 }
  validates :remaining_ml, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :storage_type, presence: true
  validates :status, presence: true
  validates :stored_at, presence: true
  validates :expires_at, presence: true

  before_validation :set_expiration, on: :create
  before_save :recalculate_expiration_if_changed

  scope :in_stock, -> { available.where("remaining_ml > 0") }
  scope :in_fridge, -> { where(storage_type: "fridge") }
  scope :in_freezer, -> { where(storage_type: "freezer") }
  scope :at_room_temp, -> { where(storage_type: "room_temp") }
  scope :expiring_soon, ->(hours = 24) { available.where("expires_at <= ?", Time.current + hours.hours) }
  scope :expired_stashes, -> { available.where("expires_at < ?", Time.current) }
  scope :oldest_first, -> { order(stored_at: :asc) }
  scope :newest_first, -> { order(stored_at: :desc) }

  # CDC-recommended storage durations
  EXPIRATION_HOURS = {
    "room_temp" => 4,    # Up to 4 hours at room temp (77°F / 25°C)
    "fridge"    => 96,   # Up to 4 days in fridge (40°F / 4°C)
    "freezer"   => 4320  # Up to 6 months in freezer (0°F / -18°C) — using 180 days
  }.freeze

  def expired?
    expires_at < Time.current
  end

  def hours_until_expiry
    return 0 if expired?
    ((expires_at - Time.current) / 1.hour).round(1)
  end

  def consume!(volume:, user:, feeding: nil, notes: nil)
    validate_withdrawal!(volume)

    transaction do
      self.remaining_ml -= volume
      update_status_after_withdrawal!

      milk_stash_logs.create!(
        user: user,
        action: "consumed",
        volume_ml: volume,
        feeding: feeding,
        notes: notes
      )
    end
  end

  def discard!(volume:, user:, reason: nil, notes: nil)
    validate_withdrawal!(volume)

    transaction do
      self.remaining_ml -= volume
      update_status_after_withdrawal!(:discarded)

      milk_stash_logs.create!(
        user: user,
        action: "discarded",
        volume_ml: volume,
        reason: reason,
        notes: notes
      )
    end
  end

  def transfer!(user:, destination:, notes: nil)
    raise "Cannot transfer — not available" unless available?
    raise "Cannot transfer to same storage type" if destination == storage_type
    raise "Cannot transfer to room_temp" if destination == "room_temp"

    transaction do
      old_storage = storage_type

      self.storage_type = destination
      self.expires_at = compute_expiration(destination)
      self.thawed_at = Time.current if old_storage == "freezer" && destination == "fridge"
      save!

      milk_stash_logs.create!(
        user: user,
        action: "transferred",
        volume_ml: remaining_ml,
        destination_storage_type: destination,
        notes: notes || "Transferred from #{old_storage} to #{destination}"
      )
    end
  end

  def mark_expired!(user: nil)
    return unless available? && expired?

    transaction do
      update!(status: "expired")

      if user
        milk_stash_logs.create!(
          user: user,
          action: "discarded",
          volume_ml: remaining_ml,
          reason: "expired",
          notes: "Auto-marked as expired"
        )
      end
    end
  end

  private

  def set_expiration
    self.stored_at ||= Time.current
    self.remaining_ml = volume_ml if remaining_ml.blank?
    self.expires_at ||= compute_expiration(storage_type)
  end

  def compute_expiration(type)
    hours = EXPIRATION_HOURS[type.to_s] || 96
    (stored_at || Time.current) + hours.hours
  end

  def recalculate_expiration_if_changed
    return if new_record? # handled by set_expiration
    if (storage_type_changed? || stored_at_changed?) && !expires_at_changed?
      self.expires_at = compute_expiration(storage_type)
    end
  end

  def validate_withdrawal!(volume)
    raise "Cannot withdraw from non-available stash" unless available?
    raise "Cannot withdraw #{volume}ml — only #{remaining_ml}ml remaining" if volume > remaining_ml
    raise "Volume must be positive" if volume <= 0
  end

  def update_status_after_withdrawal!(empty_status = :consumed)
    if remaining_ml.zero?
      self.status = empty_status
    end
    save!
  end
end
