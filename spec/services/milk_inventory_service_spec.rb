require 'rails_helper'

RSpec.describe MilkInventoryService do
  let(:baby) { create(:baby) }
  let(:user) { create(:user) }

  describe "#call" do
    before do
      create(:milk_stash, :in_fridge, baby: baby, user: user, volume_ml: 100, remaining_ml: 100, label: "Fridge A")
      create(:milk_stash, :in_fridge, baby: baby, user: user, volume_ml: 80, remaining_ml: 50, label: "Fridge B")
      create(:milk_stash, :in_freezer, baby: baby, user: user, volume_ml: 150, remaining_ml: 150, label: "Freezer A")
      create(:milk_stash, :at_room_temp, baby: baby, user: user, volume_ml: 60, remaining_ml: 60, label: "Counter")
      create(:milk_stash, :fully_consumed, baby: baby, user: user) # should not count
    end

    subject { described_class.new(baby).call }

    it "returns correct total summary" do
      expect(subject[:summary][:total_ml]).to eq(360)
      expect(subject[:summary][:total_bags]).to eq(4)
    end

    it "breaks down by storage type" do
      fridge = subject[:by_storage_type][:fridge]
      expect(fridge[:total_ml]).to eq(150) # 100 + 50
      expect(fridge[:count]).to eq(2)
      expect(fridge[:items].length).to eq(2)

      freezer = subject[:by_storage_type][:freezer]
      expect(freezer[:total_ml]).to eq(150)
      expect(freezer[:count]).to eq(1)

      room = subject[:by_storage_type][:room_temp]
      expect(room[:total_ml]).to eq(60)
      expect(room[:count]).to eq(1)
    end

    it "does not include consumed stashes" do
      expect(subject[:summary][:total_bags]).to eq(4)
    end
  end

  describe "expiring_soon" do
    it "detects stashes expiring within 6 hours" do
      create(:milk_stash, :expiring_soon, baby: baby, user: user, label: "expiring")
      create(:milk_stash, :in_fridge, baby: baby, user: user, label: "ok")

      result = described_class.new(baby).call
      expect(result[:expiring_soon][:count]).to eq(1)
      expect(result[:expiring_soon][:items][0][:label]).to eq("expiring")
    end
  end

  describe "expired_count" do
    it "counts available but expired stashes" do
      create(:milk_stash, :expired, baby: baby, user: user)
      create(:milk_stash, :expired, baby: baby, user: user)
      create(:milk_stash, :in_fridge, baby: baby, user: user)

      result = described_class.new(baby).call
      expect(result[:expired_count]).to eq(2)
    end
  end
end
