class Baby < ApplicationRecord
  belongs_to :user, optional: true
  has_many :feedings, dependent: :destroy
  has_many :weight_logs, dependent: :destroy
  has_many :vaccinations, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :milk_stashes, dependent: :destroy
  has_many :diaper_changes, dependent: :destroy
  has_many :milestones, dependent: :destroy
  has_many :sleep_logs, dependent: :destroy

  validates :name, presence: true
  validates :date_of_birth, presence: true
  validates :gender, inclusion: { in: %w[male female], allow_blank: true }
  validates :birth_weight_grams, numericality: { greater_than: 0 }, allow_nil: true

  def age_in_days
    (Date.current - date_of_birth).to_i
  end

  def age_in_weeks
    age_in_days / 7
  end
end
