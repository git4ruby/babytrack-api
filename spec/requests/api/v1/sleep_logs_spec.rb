require 'rails_helper'

RSpec.describe "Api::V1::SleepLogs", type: :request do
  let!(:user) { create(:user) }
  let!(:baby) { create(:baby, user: user) }
  let(:headers) { auth_headers(user) }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/sleep_logs" do
    it "returns sleep logs" do
      create_list(:sleep_log, 3, baby: baby, user: user)

      get "/api/v1/sleep_logs", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(3)
    end

    it "filters by date" do
      today_noon = Time.zone.parse(Date.current.to_s + " 12:00:00")
      create(:sleep_log, baby: baby, user: user, started_at: today_noon, ended_at: today_noon + 1.hour)
      create(:sleep_log, baby: baby, user: user, started_at: 3.days.ago, ended_at: 3.days.ago + 1.hour)

      get "/api/v1/sleep_logs", params: { date: Date.current.to_s }, headers: headers

      expect(json_body["data"].length).to eq(1)
    end

    it "filters by date range" do
      create(:sleep_log, baby: baby, user: user, started_at: 1.day.ago, ended_at: 1.day.ago + 1.hour)
      create(:sleep_log, baby: baby, user: user, started_at: 10.days.ago, ended_at: 10.days.ago + 1.hour)

      get "/api/v1/sleep_logs",
        params: { from: 3.days.ago.to_date.to_s, to: Date.current.to_s },
        headers: headers

      expect(json_body["data"].length).to eq(1)
    end

    it "returns 401 without auth" do
      get "/api/v1/sleep_logs"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/sleep_logs" do
    it "creates a nap" do
      params = {
        sleep_log: {
          sleep_type: "nap",
          started_at: 2.hours.ago.iso8601,
          ended_at: 1.hour.ago.iso8601,
          location: "crib"
        }
      }

      post "/api/v1/sleep_logs", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["sleep_type"]).to eq("nap")
      expect(json_body["data"]["location"]).to eq("crib")
      expect(json_body["data"]["duration_minutes"]).to eq(60)
    end

    it "creates a night sleep" do
      params = {
        sleep_log: {
          sleep_type: "night",
          started_at: 10.hours.ago.iso8601,
          ended_at: 2.hours.ago.iso8601,
          location: "bassinet"
        }
      }

      post "/api/v1/sleep_logs", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["sleep_type"]).to eq("night")
      expect(json_body["data"]["duration_minutes"]).to eq(480)
    end

    it "returns errors for invalid data" do
      params = { sleep_log: { started_at: Time.current.iso8601 } }

      post "/api/v1/sleep_logs", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"]).to be_present
    end
  end

  describe "PATCH /api/v1/sleep_logs/:id" do
    it "updates a sleep log" do
      log = create(:sleep_log, baby: baby, user: user, location: "crib")

      patch "/api/v1/sleep_logs/#{log.id}",
        params: { sleep_log: { location: "bassinet" } },
        headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["location"]).to eq("bassinet")
    end

    it "recalculates duration when ended_at changes" do
      log = create(:sleep_log, baby: baby, user: user,
        started_at: 3.hours.ago, ended_at: 2.hours.ago)

      patch "/api/v1/sleep_logs/#{log.id}",
        params: { sleep_log: { ended_at: 1.hour.ago.iso8601 } },
        headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["duration_minutes"]).to eq(120)
    end
  end

  describe "DELETE /api/v1/sleep_logs/:id" do
    it "deletes a sleep log" do
      log = create(:sleep_log, baby: baby, user: user)

      delete "/api/v1/sleep_logs/#{log.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(SleepLog.find_by(id: log.id)).to be_nil
    end
  end

  describe "GET /api/v1/sleep_logs/summary" do
    it "returns daily sleep summary" do
      today_noon = Time.zone.parse(Date.current.to_s + " 12:00:00")
      create(:sleep_log, :nap, baby: baby, user: user,
        started_at: today_noon - 3.hours, ended_at: today_noon - 2.hours)
      create(:sleep_log, :nap, baby: baby, user: user,
        started_at: today_noon - 1.hour, ended_at: today_noon)
      create(:sleep_log, :night, baby: baby, user: user,
        started_at: today_noon + 1.hour, ended_at: today_noon + 5.hours)

      get "/api/v1/sleep_logs/summary", params: { date: Date.current.to_s }, headers: headers

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["sessions"]).to eq(3)
      expect(data["nap_count"]).to eq(2)
      expect(data["nap_minutes"]).to eq(120)
      expect(data["night_minutes"]).to eq(240)
      expect(data["total_sleep_minutes"]).to eq(360)
      expect(data["total_sleep_hours"]).to eq(6.0)
    end

    it "defaults to current date when no date param" do
      get "/api/v1/sleep_logs/summary", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["date"]).to eq(Date.current.to_s)
    end
  end
end
