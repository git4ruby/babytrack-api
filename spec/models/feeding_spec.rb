require 'rails_helper'

RSpec.describe Feeding, type: :model do
  describe "associations" do
    it { should belong_to(:baby) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:feed_type) }
    it { should validate_presence_of(:started_at) }

    context "bottle feed" do
      subject { build(:feeding, :bottle, volume_ml: nil) }
      it "requires volume_ml" do
        expect(subject).not_to be_valid
        expect(subject.errors[:volume_ml]).to include("is required for bottle/pump feeds")
      end
    end

    context "breastfeed" do
      subject { build(:feeding, :breastfeed, breast_side: nil) }
      it "requires breast_side" do
        expect(subject).not_to be_valid
        expect(subject.errors[:breast_side]).to include("is required for breastfeed")
      end
    end

    context "pump" do
      subject { build(:feeding, :pump, volume_ml: nil) }
      it "requires volume_ml" do
        expect(subject).not_to be_valid
      end
    end
  end

  describe "scopes" do
    let(:baby) { create(:baby) }
    let(:user) { create(:user) }

    it ".for_date returns feedings for a specific date" do
      today = create(:feeding, baby: baby, user: user, started_at: Time.current)
      yesterday = create(:feeding, baby: baby, user: user, started_at: 1.day.ago)

      expect(Feeding.for_date(Date.current)).to include(today)
      expect(Feeding.for_date(Date.current)).not_to include(yesterday)
    end

    it ".bottles returns only bottle feeds" do
      bottle = create(:feeding, :bottle, baby: baby, user: user)
      breast = create(:feeding, :breastfeed, baby: baby, user: user)

      expect(Feeding.bottles).to include(bottle)
      expect(Feeding.bottles).not_to include(breast)
    end
  end

  describe "soft delete" do
    it "excludes discarded records by default" do
      feeding = create(:feeding)
      feeding.discard

      expect(Feeding.all).not_to include(feeding)
      expect(Feeding.unscoped.where(id: feeding.id)).to exist
    end
  end

  describe "#compute_duration" do
    it "computes duration from started_at and ended_at" do
      feeding = create(:feeding, :breastfeed,
        started_at: 30.minutes.ago,
        ended_at: Time.current
      )
      expect(feeding.duration_minutes).to eq(30)
    end
  end
end
