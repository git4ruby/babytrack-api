require 'rails_helper'

RSpec.describe WeightLog, type: :model do
  describe "associations" do
    it { should belong_to(:baby) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:recorded_at) }
    it { should validate_presence_of(:weight_grams) }
    it { should validate_numericality_of(:weight_grams).is_greater_than(0) }
  end
end
