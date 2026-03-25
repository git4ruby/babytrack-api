require 'rails_helper'

RSpec.describe FeedingSummaryService do
  let(:baby) { create(:baby) }
  let(:user) { create(:user) }
  let(:today) { Date.current }

  describe "#call" do
    before do
      create(:feeding, :bottle, baby: baby, user: user,
        started_at: today.to_time.change(hour: 6), volume_ml: 60, milk_type: "breast_milk")
      create(:feeding, :bottle, baby: baby, user: user,
        started_at: today.to_time.change(hour: 9), volume_ml: 80, milk_type: "formula")
      create(:feeding, :breastfeed, baby: baby, user: user,
        started_at: today.to_time.change(hour: 12),
        ended_at: today.to_time.change(hour: 12, min: 20),
        breast_side: "left")
      create(:feeding, :breastfeed, baby: baby, user: user,
        started_at: today.to_time.change(hour: 15),
        ended_at: today.to_time.change(hour: 15, min: 15),
        breast_side: "right")
      create(:feeding, :pump, baby: baby, user: user,
        started_at: today.to_time.change(hour: 18), volume_ml: 100)
    end

    subject { described_class.new(baby, today).call }

    it "counts total feeds" do
      expect(subject[:total_feeds]).to eq(5)
    end

    it "sums total ml" do
      expect(subject[:total_ml]).to eq(240) # 60 + 80 + 100
    end

    it "sums bottle ml" do
      expect(subject[:bottle_ml]).to eq(140) # 60 + 80
    end

    it "sums pump ml" do
      expect(subject[:pump_ml]).to eq(100)
    end

    it "sums formula ml" do
      expect(subject[:formula_ml]).to eq(80)
    end

    it "computes breast duration per side" do
      expect(subject[:breast_duration_minutes][:left]).to eq(20)
      expect(subject[:breast_duration_minutes][:right]).to eq(15)
      expect(subject[:breast_duration_minutes][:total]).to eq(35)
    end

    it "computes breast balance" do
      expect(subject[:breast_balance][:left_percent]).to be_within(1).of(57.1)
      expect(subject[:breast_balance][:right_percent]).to be_within(1).of(42.9)
    end

    it "counts feeds by type" do
      expect(subject[:feeds_by_type]).to eq({ bottle: 2, breastfeed: 2, pump: 1 })
    end

    it "computes average gap hours" do
      expect(subject[:average_gap_hours]).to eq(3.0)
    end

    it "computes longest gap hours" do
      expect(subject[:longest_gap_hours]).to eq(3.0)
    end
  end

  describe "empty day" do
    subject { described_class.new(baby, today).call }

    it "returns zeros" do
      expect(subject[:total_feeds]).to eq(0)
      expect(subject[:total_ml]).to eq(0)
      expect(subject[:average_gap_hours]).to eq(0)
    end
  end
end
