class MilkStashLog < ApplicationRecord
  belongs_to :milk_stash
  belongs_to :user
  belongs_to :feeding, optional: true

  enum :action, {
    consumed: "consumed",
    discarded: "discarded",
    transferred: "transferred"
  }, prefix: true

  validates :action, presence: true
  validates :volume_ml, presence: true, numericality: { greater_than: 0 }

  scope :consumptions, -> { action_consumed }
  scope :discards, -> { action_discarded }
  scope :transfers, -> { action_transferred }
  scope :recent, -> { order(created_at: :desc) }
end
