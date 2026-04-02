class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :babies
  has_many :baby_shares
  has_many :shared_babies, through: :baby_shares, source: :baby

  validates :name, presence: true
  validates :role, inclusion: { in: %w[parent caregiver] }

  before_create :set_default_jti

  private

  def set_default_jti
    self.jti ||= SecureRandom.uuid
  end
end
