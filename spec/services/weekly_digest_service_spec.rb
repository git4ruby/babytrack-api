require 'rails_helper'

RSpec.describe WeeklyDigestService do
  let!(:user) { create(:user) }
  let!(:baby) { create(:baby, user: user) }
  let(:from_date) { Date.new(2026, 3, 23) }
  let(:to_date) { Date.new(2026, 3, 29) }

  subject { described_class.new(baby, from_date, to_date).call }

  describe "feeding stats" do
    it "computes feeding count, volume, and daily average" do
      tz = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
      mid_week = tz.parse("2026-03-25 12:00:00")

      create(:feeding, :bottle, baby: baby, user: user, started_at: mid_week, volume_ml: 60)
      create(:feeding, :bottle, baby: baby, user: user, started_at: mid_week + 2.hours, volume_ml: 80)
      create(:feeding, :breastfeed, baby: baby, user: user,
        started_at: mid_week + 4.hours, ended_at: mid_week + 4.hours + 30.minutes)

      stats = subject[:feeding]
      expect(stats[:count]).to eq(3)
      expect(stats[:total_volume_ml]).to eq(140)
      expect(stats[:avg_daily_feeds]).to eq(0.4) # 3 feeds / 7 days
    end

    it "returns zeros when no feedings" do
      stats = subject[:feeding]
      expect(stats[:count]).to eq(0)
      expect(stats[:total_volume_ml]).to eq(0)
      expect(stats[:avg_daily_feeds]).to eq(0.0)
    end
  end

  describe "diaper stats" do
    it "computes diaper totals by type" do
      tz = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
      mid_week = tz.parse("2026-03-25 12:00:00")

      create(:diaper_change, baby: baby, user: user, diaper_type: "wet", changed_at: mid_week)
      create(:diaper_change, baby: baby, user: user, diaper_type: "wet", changed_at: mid_week + 1.hour)
      create(:diaper_change, :soiled, baby: baby, user: user, changed_at: mid_week + 2.hours)
      create(:diaper_change, :both, baby: baby, user: user, changed_at: mid_week + 3.hours)

      stats = subject[:diapers]
      expect(stats[:total]).to eq(4)
      expect(stats[:wet]).to eq(3)    # 2 wet + 1 both
      expect(stats[:soiled]).to eq(2) # 1 soiled + 1 both
      expect(stats[:dry]).to eq(0)
    end

    it "returns zeros when no diaper changes" do
      stats = subject[:diapers]
      expect(stats[:total]).to eq(0)
      expect(stats[:wet]).to eq(0)
      expect(stats[:soiled]).to eq(0)
    end
  end

  describe "sleep stats" do
    it "computes total and average daily sleep hours" do
      tz = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
      mid_week = tz.parse("2026-03-25 12:00:00")

      create(:sleep_log, :nap, baby: baby, user: user,
        started_at: mid_week, ended_at: mid_week + 1.hour, duration_minutes: 60)
      create(:sleep_log, :night, baby: baby, user: user,
        started_at: mid_week + 10.hours, ended_at: mid_week + 18.hours, duration_minutes: 480)

      stats = subject[:sleep]
      expect(stats[:total_hours]).to eq(9.0)         # (60 + 480) / 60
      expect(stats[:avg_daily_hours]).to eq(1.3)      # 9.0 / 7
    end

    it "returns zeros when no sleep logs" do
      stats = subject[:sleep]
      expect(stats[:total_hours]).to eq(0.0)
      expect(stats[:avg_daily_hours]).to eq(0.0)
    end
  end

  describe "milestone stats" do
    it "returns milestones achieved in the date range" do
      inside = create(:milestone, baby: baby, user: user,
        title: "First smile", achieved_on: Date.new(2026, 3, 25))
      outside = create(:milestone, baby: baby, user: user,
        title: "Rolled over", achieved_on: Date.new(2026, 3, 15))

      milestones = subject[:milestones]
      expect(milestones).to include(inside)
      expect(milestones).not_to include(outside)
    end

    it "orders milestones by achieved_on" do
      later = create(:milestone, baby: baby, user: user,
        title: "Second", achieved_on: Date.new(2026, 3, 28))
      earlier = create(:milestone, baby: baby, user: user,
        title: "First", achieved_on: Date.new(2026, 3, 24))

      milestones = subject[:milestones]
      expect(milestones.first).to eq(earlier)
      expect(milestones.last).to eq(later)
    end
  end

  describe "weight stats" do
    it "computes weight change from previous entry" do
      tz = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

      # Previous weight before the range
      create(:weight_log, baby: baby, user: user,
        weight_grams: 3200, recorded_at: tz.parse("2026-03-20 12:00:00"))

      # Weight within the range
      create(:weight_log, baby: baby, user: user,
        weight_grams: 3400, recorded_at: tz.parse("2026-03-25 12:00:00"))
      create(:weight_log, baby: baby, user: user,
        weight_grams: 3500, recorded_at: tz.parse("2026-03-28 12:00:00"))

      stats = subject[:weight]
      expect(stats[:entries].length).to eq(2)
      expect(stats[:change_grams]).to eq(300) # 3500 - 3200
    end

    it "returns nil change when no previous weight exists" do
      tz = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
      create(:weight_log, baby: baby, user: user,
        weight_grams: 3400, recorded_at: tz.parse("2026-03-25 12:00:00"))

      stats = subject[:weight]
      expect(stats[:change_grams]).to be_nil
    end

    it "returns empty result when no weight entries" do
      stats = subject[:weight]
      expect(stats[:entries]).to be_empty
      expect(stats[:change_grams]).to be_nil
    end
  end
end
