require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_inclusion_of(:role).in_array(%w[parent caregiver]) }
  end

  describe "jti" do
    it "sets a default jti before creation" do
      user = create(:user)
      expect(user.jti).to be_present
    end
  end
end
