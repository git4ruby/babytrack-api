require 'rails_helper'

RSpec.describe MilkStash, type: :model do
  let(:baby) { create(:baby) }
  let(:user) { create(:user) }

  describe "associations" do
    it { should belong_to(:baby) }
    it { should belong_to(:user) }
    it { should have_many(:milk_stash_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:volume_ml) }
    it { should validate_presence_of(:storage_type) }
    # stored_at is auto-set by before_validation callback, so shoulda can't test it
    it { should validate_numericality_of(:volume_ml).is_greater_than(0) }
    it { should validate_numericality_of(:remaining_ml).is_greater_than_or_equal_to(0) }
  end

  describe "auto-set expiration" do
    it "sets fridge expiration to 4 days" do
      stash = create(:milk_stash, :in_fridge, baby: baby, user: user, stored_at: Time.current)
      expect(stash.expires_at).to be_within(1.minute).of(Time.current + 96.hours)
    end

    it "sets freezer expiration to 6 months" do
      stash = create(:milk_stash, :in_freezer, baby: baby, user: user, stored_at: Time.current, expires_at: nil)
      expect(stash.expires_at).to be_within(1.minute).of(Time.current + 4320.hours)
    end

    it "sets room temp expiration to 4 hours" do
      stash = create(:milk_stash, :at_room_temp, baby: baby, user: user, stored_at: Time.current, expires_at: nil)
      expect(stash.expires_at).to be_within(1.minute).of(Time.current + 4.hours)
    end

    it "sets remaining_ml to volume_ml on create" do
      stash = create(:milk_stash, baby: baby, user: user, volume_ml: 120, remaining_ml: nil)
      expect(stash.remaining_ml).to eq(120)
    end
  end

  describe "#expired?" do
    it "returns true when past expiration" do
      stash = create(:milk_stash, :expired, baby: baby, user: user)
      expect(stash.expired?).to be true
    end

    it "returns false when not expired" do
      stash = create(:milk_stash, :in_fridge, baby: baby, user: user)
      expect(stash.expired?).to be false
    end
  end

  describe "#hours_until_expiry" do
    it "returns positive hours for non-expired stash" do
      stash = create(:milk_stash, :in_fridge, baby: baby, user: user)
      expect(stash.hours_until_expiry).to be > 0
    end

    it "returns 0 for expired stash" do
      stash = create(:milk_stash, :expired, baby: baby, user: user)
      expect(stash.hours_until_expiry).to eq(0)
    end
  end

  describe "#consume!" do
    let!(:stash) { create(:milk_stash, baby: baby, user: user, volume_ml: 100, remaining_ml: 100) }

    context "full consumption" do
      it "marks as consumed and sets remaining to 0" do
        stash.consume!(volume: 100, user: user)

        expect(stash.remaining_ml).to eq(0)
        expect(stash.status).to eq("consumed")
      end

      it "creates a log entry" do
        expect {
          stash.consume!(volume: 100, user: user)
        }.to change(MilkStashLog, :count).by(1)

        log = stash.milk_stash_logs.last
        expect(log.action).to eq("consumed")
        expect(log.volume_ml).to eq(100)
      end
    end

    context "partial consumption" do
      it "reduces remaining_ml and stays available" do
        stash.consume!(volume: 40, user: user)

        expect(stash.remaining_ml).to eq(60)
        expect(stash.status).to eq("available")
      end

      it "allows multiple partial consumptions" do
        stash.consume!(volume: 30, user: user, notes: "First draw")
        stash.consume!(volume: 30, user: user, notes: "Second draw")

        expect(stash.remaining_ml).to eq(40)
        expect(stash.milk_stash_logs.count).to eq(2)
      end

      it "marks as consumed when remainder reaches 0" do
        stash.consume!(volume: 60, user: user)
        stash.consume!(volume: 40, user: user)

        expect(stash.remaining_ml).to eq(0)
        expect(stash.status).to eq("consumed")
      end
    end

    context "with linked feeding" do
      it "stores the feeding reference" do
        feeding = create(:feeding, baby: baby, user: user)
        stash.consume!(volume: 60, user: user, feeding: feeding)

        log = stash.milk_stash_logs.last
        expect(log.feeding_id).to eq(feeding.id)
      end
    end

    context "error cases" do
      it "raises when consuming more than remaining" do
        expect {
          stash.consume!(volume: 150, user: user)
        }.to raise_error(RuntimeError, /only 100ml remaining/)
      end

      it "raises when consuming from non-available stash" do
        stash.update!(status: "discarded", remaining_ml: 0)
        expect {
          stash.consume!(volume: 10, user: user)
        }.to raise_error(RuntimeError, /non-available/)
      end

      it "raises when volume is 0 or negative" do
        expect {
          stash.consume!(volume: 0, user: user)
        }.to raise_error(RuntimeError, /positive/)
      end
    end
  end

  describe "#discard!" do
    let!(:stash) { create(:milk_stash, baby: baby, user: user, volume_ml: 100, remaining_ml: 100) }

    context "full discard" do
      it "marks as discarded" do
        stash.discard!(volume: 100, user: user, reason: "expired")

        expect(stash.remaining_ml).to eq(0)
        expect(stash.status).to eq("discarded")
      end

      it "creates a log with reason" do
        stash.discard!(volume: 100, user: user, reason: "spilled")

        log = stash.milk_stash_logs.last
        expect(log.action).to eq("discarded")
        expect(log.reason).to eq("spilled")
      end
    end

    context "partial discard" do
      it "reduces remaining and stays available" do
        stash.discard!(volume: 30, user: user, reason: "contaminated")

        expect(stash.remaining_ml).to eq(70)
        expect(stash.status).to eq("available")
      end
    end
  end

  describe "#transfer!" do
    let!(:stash) { create(:milk_stash, :in_freezer, baby: baby, user: user, volume_ml: 100, remaining_ml: 100) }

    it "transfers from freezer to fridge" do
      stash.transfer!(user: user, destination: "fridge")

      expect(stash.storage_type).to eq("fridge")
      expect(stash.thawed_at).to be_within(1.second).of(Time.current)
    end

    it "updates expiration based on new storage type" do
      stash.transfer!(user: user, destination: "fridge")

      # After thawing, expiration should be based on fridge rules
      expect(stash.expires_at).to be_within(1.minute).of(stash.stored_at + 96.hours)
    end

    it "creates a transfer log" do
      stash.transfer!(user: user, destination: "fridge")

      log = stash.milk_stash_logs.last
      expect(log.action).to eq("transferred")
      expect(log.destination_storage_type).to eq("fridge")
      expect(log.volume_ml).to eq(100)
    end

    it "raises when transferring to same type" do
      expect {
        stash.transfer!(user: user, destination: "freezer")
      }.to raise_error(RuntimeError, /same storage/)
    end

    it "raises when transferring to room_temp" do
      expect {
        stash.transfer!(user: user, destination: "room_temp")
      }.to raise_error(RuntimeError, /room_temp/)
    end
  end

  describe "#mark_expired!" do
    it "marks available expired stash as expired" do
      stash = create(:milk_stash, :expired, baby: baby, user: user)
      stash.mark_expired!(user: user)

      expect(stash.status).to eq("expired")
    end

    it "does not change non-expired stash" do
      stash = create(:milk_stash, :in_fridge, baby: baby, user: user)
      stash.mark_expired!(user: user)

      expect(stash.status).to eq("available")
    end
  end

  describe "scopes" do
    before do
      create(:milk_stash, :in_fridge, baby: baby, user: user, label: "fridge1")
      create(:milk_stash, :in_freezer, baby: baby, user: user, label: "freezer1")
      create(:milk_stash, :at_room_temp, baby: baby, user: user, label: "counter1")
      # fully_consumed defaults to fridge storage_type but has consumed status
      create(:milk_stash, :fully_consumed, baby: baby, user: user, label: "done1")
    end

    it ".in_stock returns available with remaining > 0" do
      expect(MilkStash.in_stock.count).to eq(3)
    end

    it ".in_fridge returns fridge stashes (regardless of status)" do
      # 2: fridge1 (available) + done1 (consumed, but still fridge type)
      expect(MilkStash.in_fridge.count).to eq(2)
    end

    it ".in_fridge.available returns only available fridge stashes" do
      expect(MilkStash.in_fridge.available.count).to eq(1)
      expect(MilkStash.in_fridge.available.first.label).to eq("fridge1")
    end

    it ".in_freezer returns only freezer stashes" do
      expect(MilkStash.in_freezer.count).to eq(1)
    end

    it ".at_room_temp returns only room temp stashes" do
      expect(MilkStash.at_room_temp.count).to eq(1)
    end
  end
end
