class BabyShare < ApplicationRecord
  belongs_to :baby
  belongs_to :user, optional: true  # nil until invite is accepted

  enum :role, { caregiver: "caregiver", viewer: "viewer" }
  enum :status, { pending: "pending", accepted: "accepted" }

  validates :invite_email, presence: true
  validates :baby_id, uniqueness: { scope: :user_id, message: "already shared with this user" }, if: -> { user_id.present? }

  before_create :generate_invite_token

  private

  def generate_invite_token
    self.invite_token ||= SecureRandom.hex(20)
  end
end
