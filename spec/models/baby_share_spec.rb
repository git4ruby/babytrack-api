require 'rails_helper'

RSpec.describe BabyShare, type: :model do
  describe "associations" do
    it { should belong_to(:baby) }
    it { should belong_to(:user).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:invite_email) }

    it "enforces uniqueness of baby_id scoped to user_id when user is present" do
      user = create(:user)
      baby = create(:baby)
      create(:baby_share, :accepted, baby: baby, user: user)

      duplicate = build(:baby_share, baby: baby, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:baby_id]).to include("already shared with this user")
    end

    it "allows multiple pending shares without a user" do
      baby = create(:baby)
      create(:baby_share, baby: baby, user: nil)
      second = build(:baby_share, baby: baby, user: nil)
      expect(second).to be_valid
    end
  end

  describe "token generation" do
    it "generates an invite_token on create" do
      share = create(:baby_share)
      expect(share.invite_token).to be_present
      expect(share.invite_token.length).to eq(40) # hex(20) = 40 chars
    end

    it "does not overwrite an existing token" do
      share = build(:baby_share, invite_token: "custom_token_123")
      share.save!
      expect(share.invite_token).to eq("custom_token_123")
    end
  end

  describe "enums" do
    it "defines role enum" do
      share = build(:baby_share, role: "caregiver")
      expect(share).to be_caregiver

      share.role = "viewer"
      expect(share).to be_viewer
    end

    it "defines status enum" do
      share = build(:baby_share, status: "pending")
      expect(share).to be_pending

      share.status = "accepted"
      expect(share).to be_accepted
    end
  end

  describe "scopes" do
    let(:baby) { create(:baby) }

    it ".pending returns only pending shares" do
      pending_share = create(:baby_share, baby: baby)
      accepted_share = create(:baby_share, :accepted, baby: baby)

      expect(BabyShare.pending).to include(pending_share)
      expect(BabyShare.pending).not_to include(accepted_share)
    end

    it ".accepted returns only accepted shares" do
      pending_share = create(:baby_share, baby: baby)
      accepted_share = create(:baby_share, :accepted, baby: baby)

      expect(BabyShare.accepted).to include(accepted_share)
      expect(BabyShare.accepted).not_to include(pending_share)
    end
  end
end
