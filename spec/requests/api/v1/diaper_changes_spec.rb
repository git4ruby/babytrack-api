require 'rails_helper'

RSpec.describe "Api::V1::DiaperChanges", type: :request do
  let!(:user) { create(:user) }
  let!(:baby) { create(:baby, user: user) }
  let(:headers) { auth_headers(user) }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/diaper_changes" do
    it "returns diaper changes" do
      create(:diaper_change, baby: baby, user: user)
      create(:diaper_change, :soiled, baby: baby, user: user)

      get "/api/v1/diaper_changes", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(2)
    end

    it "filters by diaper_type" do
      create(:diaper_change, baby: baby, user: user, diaper_type: "wet")
      create(:diaper_change, :soiled, baby: baby, user: user)

      get "/api/v1/diaper_changes", params: { diaper_type: "wet" }, headers: headers

      expect(json_body["data"].length).to eq(1)
    end
  end

  describe "POST /api/v1/diaper_changes" do
    it "creates a wet diaper change" do
      post "/api/v1/diaper_changes",
        params: { diaper_change: { changed_at: Time.current.iso8601, diaper_type: "wet" } },
        headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["diaper_type"]).to eq("wet")
    end

    it "creates a soiled diaper change with details" do
      post "/api/v1/diaper_changes",
        params: { diaper_change: {
          changed_at: Time.current.iso8601,
          diaper_type: "soiled",
          stool_color: "yellow",
          consistency: "seedy",
          has_rash: true,
          notes: "Mild rash noticed"
        } },
        headers: headers, as: :json

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["stool_color"]).to eq("yellow")
      expect(data["consistency"]).to eq("seedy")
      expect(data["has_rash"]).to be true
    end
  end

  describe "DELETE /api/v1/diaper_changes/:id" do
    it "deletes a diaper change" do
      change = create(:diaper_change, baby: baby, user: user)

      delete "/api/v1/diaper_changes/#{change.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(DiaperChange.exists?(change.id)).to be false
    end
  end

  describe "GET /api/v1/diaper_changes/summary" do
    it "returns daily summary" do
      today_noon = Time.zone.parse(Date.current.to_s + " 12:00:00")
      create(:diaper_change, baby: baby, user: user, diaper_type: "wet", changed_at: today_noon)
      create(:diaper_change, baby: baby, user: user, diaper_type: "wet", changed_at: today_noon + 2.hours)
      create(:diaper_change, :soiled, baby: baby, user: user, changed_at: today_noon + 4.hours)
      create(:diaper_change, :both, baby: baby, user: user, changed_at: today_noon + 6.hours)

      get "/api/v1/diaper_changes/summary", params: { date: Date.current.to_s }, headers: headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["total"]).to eq(4)
      expect(data["wet"]).to eq(3)    # 2 wet + 1 both
      expect(data["soiled"]).to eq(2) # 1 soiled + 1 both
    end
  end

  describe "GET /api/v1/diaper_changes/stats" do
    it "returns multi-day stats" do
      today_noon = Time.zone.parse(Date.current.to_s + " 12:00:00")
      3.times { create(:diaper_change, baby: baby, user: user, changed_at: today_noon) }
      2.times { create(:diaper_change, :soiled, baby: baby, user: user, changed_at: today_noon - 1.day) }

      get "/api/v1/diaper_changes/stats",
        params: { from: 1.day.ago.to_date.to_s, to: Date.current.to_s },
        headers: headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["total_changes"]).to eq(5)
      expect(data["avg_per_day"]).to eq(2.5)
    end
  end
end
