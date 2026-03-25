require 'rails_helper'

RSpec.describe Baby, type: :model do
  describe "associations" do
    it { should have_many(:feedings).dependent(:destroy) }
    it { should have_many(:weight_logs).dependent(:destroy) }
    it { should have_many(:vaccinations).dependent(:destroy) }
    it { should have_many(:appointments).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:date_of_birth) }
  end

  describe "#age_in_days" do
    it "calculates age from date of birth" do
      baby = build(:baby, date_of_birth: 14.days.ago.to_date)
      expect(baby.age_in_days).to eq(14)
    end
  end

  describe "#age_in_weeks" do
    it "calculates age in weeks" do
      baby = build(:baby, date_of_birth: 14.days.ago.to_date)
      expect(baby.age_in_weeks).to eq(2)
    end
  end
end
