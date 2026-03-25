require 'rails_helper'

RSpec.describe "Api::V1::MilkStashes", type: :request do
  let!(:user) { create(:user) }
  let!(:baby) { create(:baby, user: user) }
  let(:headers) { auth_headers(user) }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/milk_stashes" do
    it "returns available stashes by default" do
      create(:milk_stash, :in_fridge, baby: baby, user: user)
      create(:milk_stash, :in_freezer, baby: baby, user: user)
      create(:milk_stash, :fully_consumed, baby: baby, user: user)

      get "/api/v1/milk_stashes", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(2)
    end

    it "filters by storage_type" do
      create(:milk_stash, :in_fridge, baby: baby, user: user)
      create(:milk_stash, :in_freezer, baby: baby, user: user)

      get "/api/v1/milk_stashes", params: { storage_type: "fridge" }, headers: headers

      expect(json_body["data"].length).to eq(1)
      expect(json_body["data"][0]["storage_type"]).to eq("fridge")
    end

    it "returns all statuses when all=true" do
      create(:milk_stash, :in_fridge, baby: baby, user: user)
      create(:milk_stash, :fully_consumed, baby: baby, user: user)

      get "/api/v1/milk_stashes", params: { all: "true" }, headers: headers

      expect(json_body["data"].length).to eq(2)
    end
  end

  describe "POST /api/v1/milk_stashes" do
    it "creates a fridge stash with auto-expiration" do
      params = {
        milk_stash: {
          volume_ml: 120,
          storage_type: "fridge",
          label: "Morning pump"
        }
      }

      post "/api/v1/milk_stashes", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["volume_ml"]).to eq(120)
      expect(data["remaining_ml"]).to eq(120)
      expect(data["storage_type"]).to eq("fridge")
      expect(data["status"]).to eq("available")
      expect(data["hours_until_expiry"]).to be > 90 # ~96 hours
    end

    it "creates a room temp stash with 4-hour expiration" do
      params = {
        milk_stash: {
          volume_ml: 80,
          storage_type: "room_temp",
          label: "For next feed"
        }
      }

      post "/api/v1/milk_stashes", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["storage_type"]).to eq("room_temp")
      expect(data["hours_until_expiry"]).to be_between(3.5, 4.1)
    end

    it "creates a freezer stash" do
      params = {
        milk_stash: {
          volume_ml: 150,
          storage_type: "freezer",
          label: "Bag #5 - March batch"
        }
      }

      post "/api/v1/milk_stashes", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["storage_type"]).to eq("freezer")
      expect(data["hours_until_expiry"]).to be > 4000
    end
  end

  describe "POST /api/v1/milk_stashes/:id/consume" do
    let!(:stash) { create(:milk_stash, :in_fridge, baby: baby, user: user, volume_ml: 100, remaining_ml: 100) }

    it "fully consumes a stash" do
      post "/api/v1/milk_stashes/#{stash.id}/consume",
        params: { volume_ml: 100 }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["remaining_ml"]).to eq(0)
      expect(data["status"]).to eq("consumed")
    end

    it "partially consumes a stash" do
      post "/api/v1/milk_stashes/#{stash.id}/consume",
        params: { volume_ml: 40, notes: "Used for 2pm bottle" }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["remaining_ml"]).to eq(60)
      expect(data["status"]).to eq("available")
    end

    it "returns error when consuming more than remaining" do
      post "/api/v1/milk_stashes/#{stash.id}/consume",
        params: { volume_ml: 150 }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["error"]).to include("only 100ml remaining")
    end
  end

  describe "POST /api/v1/milk_stashes/:id/discard" do
    let!(:stash) { create(:milk_stash, :in_fridge, baby: baby, user: user, volume_ml: 100, remaining_ml: 100) }

    it "fully discards with reason" do
      post "/api/v1/milk_stashes/#{stash.id}/discard",
        params: { volume_ml: 100, reason: "expired" }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["remaining_ml"]).to eq(0)
      expect(data["status"]).to eq("discarded")
    end

    it "partially discards (spill)" do
      post "/api/v1/milk_stashes/#{stash.id}/discard",
        params: { volume_ml: 20, reason: "spilled", notes: "Knocked over container" },
        headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["remaining_ml"]).to eq(80)
      expect(data["status"]).to eq("available")
    end
  end

  describe "POST /api/v1/milk_stashes/:id/transfer" do
    let!(:stash) { create(:milk_stash, :in_freezer, baby: baby, user: user, volume_ml: 100, remaining_ml: 100) }

    it "transfers from freezer to fridge (thaw)" do
      post "/api/v1/milk_stashes/#{stash.id}/transfer",
        params: { destination: "fridge" }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["storage_type"]).to eq("fridge")
      expect(data["thawed_at"]).to be_present
    end

    it "returns error when transferring to same type" do
      post "/api/v1/milk_stashes/#{stash.id}/transfer",
        params: { destination: "freezer" }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/milk_stashes/:id" do
    it "returns stash with activity logs" do
      stash = create(:milk_stash, :in_fridge, baby: baby, user: user, volume_ml: 100, remaining_ml: 100)
      stash.consume!(volume: 30, user: user, notes: "First draw")

      get "/api/v1/milk_stashes/#{stash.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["remaining_ml"]).to eq(70)
      expect(json_body["logs"].length).to eq(1)
      expect(json_body["logs"][0]["log_action"]).to eq("consumed")
    end
  end

  describe "GET /api/v1/milk_stashes/inventory" do
    before do
      create(:milk_stash, :in_fridge, baby: baby, user: user, volume_ml: 100, remaining_ml: 100)
      create(:milk_stash, :in_fridge, baby: baby, user: user, volume_ml: 80, remaining_ml: 80)
      create(:milk_stash, :in_freezer, baby: baby, user: user, volume_ml: 150, remaining_ml: 150)
      create(:milk_stash, :at_room_temp, baby: baby, user: user, volume_ml: 60, remaining_ml: 60)
    end

    it "returns complete inventory breakdown" do
      get "/api/v1/milk_stashes/inventory", headers: headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]

      expect(data["summary"]["total_ml"]).to eq(390)
      expect(data["summary"]["total_bags"]).to eq(4)

      expect(data["by_storage_type"]["fridge"]["total_ml"]).to eq(180)
      expect(data["by_storage_type"]["fridge"]["count"]).to eq(2)
      expect(data["by_storage_type"]["freezer"]["total_ml"]).to eq(150)
      expect(data["by_storage_type"]["freezer"]["count"]).to eq(1)
      expect(data["by_storage_type"]["room_temp"]["total_ml"]).to eq(60)
      expect(data["by_storage_type"]["room_temp"]["count"]).to eq(1)
    end
  end

  describe "GET /api/v1/milk_stashes/history" do
    it "returns activity log" do
      stash = create(:milk_stash, :in_fridge, baby: baby, user: user, volume_ml: 100, remaining_ml: 100)
      stash.consume!(volume: 30, user: user)
      stash.consume!(volume: 20, user: user)

      get "/api/v1/milk_stashes/history", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(2)
    end
  end
end
