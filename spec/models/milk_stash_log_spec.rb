require 'rails_helper'

RSpec.describe MilkStashLog, type: :model do
  describe "associations" do
    it { should belong_to(:milk_stash) }
    it { should belong_to(:user) }
    it { should belong_to(:feeding).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:action) }
    it { should validate_presence_of(:volume_ml) }
    it { should validate_numericality_of(:volume_ml).is_greater_than(0) }
  end
end
