class DiaryEntry < ApplicationRecord
  belongs_to :baby
  belongs_to :user

  MOODS = %w[happy funny sweet proud sad neutral].freeze

  validates :content, presence: true
  validates :entry_date, presence: true
  validates :mood, inclusion: { in: MOODS }

  scope :chronological, -> { order(entry_date: :desc, created_at: :desc) }
  scope :by_mood, ->(mood) { where(mood: mood) }

  def age_at_entry
    return nil unless baby&.date_of_birth
    (entry_date - baby.date_of_birth).to_i
  end
end
