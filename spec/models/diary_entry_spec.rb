require 'rails_helper'

RSpec.describe DiaryEntry, type: :model do
  describe "associations" do
    it { should belong_to(:baby) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:entry_date) }
  end

  describe "#age_at_entry" do
    it "computes days from DOB" do
      baby = create(:baby, date_of_birth: Date.new(2026, 3, 9))
      d = build(:diary_entry, baby: baby, entry_date: Date.new(2026, 3, 23))
      expect(d.age_at_entry).to eq(14)
    end
  end
end
