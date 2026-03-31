require 'rails_helper'

RSpec.describe DiaperChange, type: :model do
  describe "associations" do
    it { should belong_to(:baby) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:diaper_type) }
  end

  describe "scopes" do
    let(:baby) { create(:baby) }
    let(:user) { create(:user) }

    it ".wet_or_both includes wet and both" do
      wet = create(:diaper_change, baby: baby, user: user, diaper_type: "wet")
      both = create(:diaper_change, :both, baby: baby, user: user)
      soiled = create(:diaper_change, :soiled, baby: baby, user: user)

      result = DiaperChange.wet_or_both
      expect(result).to include(wet, both)
      expect(result).not_to include(soiled)
    end

    it ".soiled_or_both includes soiled and both" do
      soiled = create(:diaper_change, :soiled, baby: baby, user: user)
      both = create(:diaper_change, :both, baby: baby, user: user)
      wet = create(:diaper_change, baby: baby, user: user, diaper_type: "wet")

      result = DiaperChange.soiled_or_both
      expect(result).to include(soiled, both)
      expect(result).not_to include(wet)
    end
  end
end
