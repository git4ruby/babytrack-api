require 'rails_helper'

RSpec.describe Milestone, type: :model do
  describe "associations" do
    it { should belong_to(:baby) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:achieved_on) }
  end

  describe "#age_at_milestone" do
    it "computes days from DOB" do
      baby = create(:baby, date_of_birth: Date.new(2026, 3, 9))
      m = build(:milestone, baby: baby, achieved_on: Date.new(2026, 3, 23))
      expect(m.age_at_milestone).to eq(14)
    end
  end
end
