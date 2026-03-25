require 'rails_helper'

RSpec.describe Appointment, type: :model do
  describe "associations" do
    it { should belong_to(:baby) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:scheduled_at) }
    it { should validate_presence_of(:appointment_type) }
    it { should validate_presence_of(:status) }
  end

  describe "scopes" do
    let(:baby) { create(:baby) }
    let(:user) { create(:user) }

    it ".future returns upcoming appointments" do
      future = create(:appointment, baby: baby, user: user, scheduled_at: 1.week.from_now)
      past = create(:appointment, baby: baby, user: user, scheduled_at: 1.week.ago, status: "completed")

      expect(Appointment.future).to include(future)
      expect(Appointment.future).not_to include(past)
    end
  end
end
