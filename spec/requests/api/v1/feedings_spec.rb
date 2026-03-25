require 'rails_helper'

RSpec.describe "Api::V1::Feedings", type: :request do
  let!(:user) { create(:user) }
  let!(:baby) { create(:baby) }
  let(:headers) { auth_headers(user) }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/feedings" do
    it "returns paginated feedings" do
      create_list(:feeding, 3, baby: baby, user: user)

      get "/api/v1/feedings", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(3)
      expect(json_body["meta"]["total_count"]).to eq(3)
    end

    it "filters by date" do
      create(:feeding, baby: baby, user: user, started_at: Time.current)
      create(:feeding, baby: baby, user: user, started_at: 2.days.ago)

      get "/api/v1/feedings", params: { date: Date.current.to_s }, headers: headers

      expect(json_body["data"].length).to eq(1)
    end

    it "filters by feed_type" do
      create(:feeding, :bottle, baby: baby, user: user)
      create(:feeding, :breastfeed, baby: baby, user: user)

      get "/api/v1/feedings", params: { feed_type: "bottle" }, headers: headers

      expect(json_body["data"].length).to eq(1)
      expect(json_body["data"][0]["feed_type"]).to eq("bottle")
    end

    it "returns 401 without auth" do
      get "/api/v1/feedings"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/feedings" do
    it "creates a bottle feeding" do
      params = {
        feeding: {
          feed_type: "bottle",
          started_at: Time.current.iso8601,
          volume_ml: 60,
          milk_type: "breast_milk"
        }
      }

      post "/api/v1/feedings", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["feed_type"]).to eq("bottle")
      expect(json_body["data"]["volume_ml"]).to eq(60)
    end

    it "creates a breastfeed" do
      params = {
        feeding: {
          feed_type: "breastfeed",
          started_at: 30.minutes.ago.iso8601,
          ended_at: Time.current.iso8601,
          breast_side: "left"
        }
      }

      post "/api/v1/feedings", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["breast_side"]).to eq("left")
      expect(json_body["data"]["duration_minutes"]).to eq(30)
    end

    it "returns errors for invalid data" do
      params = { feeding: { feed_type: "bottle", started_at: Time.current.iso8601 } }

      post "/api/v1/feedings", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"]).to be_present
    end
  end

  describe "PATCH /api/v1/feedings/:id" do
    it "updates a feeding" do
      feeding = create(:feeding, :bottle, baby: baby, user: user, volume_ml: 60)

      patch "/api/v1/feedings/#{feeding.id}",
        params: { feeding: { volume_ml: 80 } },
        headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["volume_ml"]).to eq(80)
    end
  end

  describe "DELETE /api/v1/feedings/:id" do
    it "soft-deletes a feeding" do
      feeding = create(:feeding, baby: baby, user: user)

      delete "/api/v1/feedings/#{feeding.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(feeding.reload.discarded?).to be true
    end
  end

  describe "GET /api/v1/feedings/last" do
    it "returns the most recent feeding" do
      create(:feeding, baby: baby, user: user, started_at: 2.hours.ago)
      latest = create(:feeding, baby: baby, user: user, started_at: 30.minutes.ago)

      get "/api/v1/feedings/last", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["id"]).to eq(latest.id)
    end
  end

  describe "GET /api/v1/feedings/summary" do
    it "returns daily summary" do
      # Use midday times to avoid timezone boundary issues
      today_noon = Time.zone.parse(Date.current.to_s + " 12:00:00")
      create(:feeding, :bottle, baby: baby, user: user, started_at: today_noon - 2.hours, volume_ml: 60)
      create(:feeding, :bottle, baby: baby, user: user, started_at: today_noon - 1.hour, volume_ml: 80)
      create(:feeding, :breastfeed, baby: baby, user: user,
        started_at: today_noon, ended_at: today_noon + 30.minutes, breast_side: "left")

      get "/api/v1/feedings/summary", params: { date: Date.current.to_s }, headers: headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["total_feeds"]).to eq(3)
      expect(data["total_ml"]).to eq(140)
      expect(data["feeds_by_type"]["bottle"]).to eq(2)
      expect(data["feeds_by_type"]["breastfeed"]).to eq(1)
    end
  end
end
