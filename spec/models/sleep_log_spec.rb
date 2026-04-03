require 'rails_helper'

RSpec.describe SleepLog, type: :model do
  describe "associations" do
    it { should belong_to(:baby) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:sleep_type) }

    it "validates location inclusion" do
      log = build(:sleep_log, location: "invalid_place")
      expect(log).not_to be_valid
      expect(log.errors[:location]).to be_present
    end

    it "allows nil location" do
      log = build(:sleep_log, location: nil)
      expect(log).to be_valid
    end

    SleepLog::LOCATIONS.each do |loc|
      it "allows location '#{loc}'" do
        log = build(:sleep_log, location: loc)
        expect(log).to be_valid
      end
    end
  end

  describe "#compute_duration" do
    it "computes duration from started_at and ended_at on save" do
      log = create(:sleep_log,
        started_at: 90.minutes.ago,
        ended_at: Time.current,
        duration_minutes: nil
      )
      expect(log.duration_minutes).to eq(90)
    end

    it "does not set duration when ended_at is nil" do
      log = create(:sleep_log, :no_end)
      expect(log.duration_minutes).to be_nil
    end

    it "recalculates duration on update" do
      log = create(:sleep_log, started_at: 2.hours.ago, ended_at: 1.hour.ago)
      expect(log.duration_minutes).to eq(60)

      log.update!(ended_at: Time.current)
      expect(log.duration_minutes).to eq(120)
    end
  end

  describe "scopes" do
    let(:baby) { create(:baby) }
    let(:user) { create(:user) }

    describe ".in_range" do
      it "returns logs within the date range" do
        inside = create(:sleep_log, baby: baby, user: user,
          started_at: 1.day.ago, ended_at: 1.day.ago + 1.hour)
        outside = create(:sleep_log, baby: baby, user: user,
          started_at: 5.days.ago, ended_at: 5.days.ago + 1.hour)

        result = SleepLog.in_range(2.days.ago.to_date, Date.current)
        expect(result).to include(inside)
        expect(result).not_to include(outside)
      end
    end

    describe ".nap" do
      it "returns only nap sleep logs" do
        nap = create(:sleep_log, :nap, baby: baby, user: user)
        night = create(:sleep_log, :night, baby: baby, user: user)

        expect(SleepLog.nap).to include(nap)
        expect(SleepLog.nap).not_to include(night)
      end
    end

    describe ".night" do
      it "returns only night sleep logs" do
        nap = create(:sleep_log, :nap, baby: baby, user: user)
        night = create(:sleep_log, :night, baby: baby, user: user)

        expect(SleepLog.night).to include(night)
        expect(SleepLog.night).not_to include(nap)
      end
    end

    describe ".for_date" do
      it "returns logs for a specific date" do
        today = create(:sleep_log, baby: baby, user: user, started_at: Time.current)
        yesterday = create(:sleep_log, baby: baby, user: user, started_at: 1.day.ago)

        expect(SleepLog.for_date(Date.current)).to include(today)
        expect(SleepLog.for_date(Date.current)).not_to include(yesterday)
      end
    end

    describe ".recent" do
      it "orders by started_at descending" do
        older = create(:sleep_log, baby: baby, user: user, started_at: 3.hours.ago)
        newer = create(:sleep_log, baby: baby, user: user, started_at: 1.hour.ago)

        expect(SleepLog.recent.first).to eq(newer)
      end
    end
  end

  describe "#display_time" do
    it "returns started_at when present" do
      log = build(:sleep_log, started_at: 1.hour.ago)
      expect(log.display_time).to eq(log.started_at)
    end

    it "falls back to created_at when started_at is nil" do
      log = create(:sleep_log, started_at: nil, ended_at: nil, duration_minutes: nil)
      expect(log.display_time).to eq(log.created_at)
    end
  end
end
