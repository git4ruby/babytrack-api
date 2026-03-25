require 'rails_helper'

RSpec.describe Vaccination, type: :model do
  describe "associations" do
    it { should belong_to(:baby) }
  end

  describe "validations" do
    it { should validate_presence_of(:vaccine_name) }
    it { should validate_presence_of(:status) }
  end

  describe "#recommended_date" do
    it "computes from baby DOB + recommended_age_days" do
      baby = create(:baby, date_of_birth: Date.new(2026, 3, 9))
      vax = create(:vaccination, baby: baby, recommended_age_days: 60)
      expect(vax.recommended_date).to eq(Date.new(2026, 5, 8))
    end
  end

  describe "#overdue?" do
    it "returns true when past recommended date and still pending" do
      baby = create(:baby, date_of_birth: 90.days.ago.to_date)
      vax = create(:vaccination, baby: baby, recommended_age_days: 60, status: "pending")
      expect(vax.overdue?).to be true
    end
  end

  describe "#due_soon?" do
    it "returns true when recommended date is within 7 days" do
      # We want recommended_date = baby.date_of_birth + 60 days = 3 days from now
      # So baby.date_of_birth = 3.days.from_now - 60.days = 57.days.ago
      baby = create(:baby, date_of_birth: 57.days.ago.to_date)
      vax = build(:vaccination, baby: baby, recommended_age_days: 60, status: "pending")
      expect(vax.due_soon?).to be true
    end
  end
end
