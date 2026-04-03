require 'rails_helper'

RSpec.describe "Api::V1::DiaryEntries", type: :request do
  let!(:user) { create(:user) }
  let!(:baby) { create(:baby, user: user) }
  let(:headers) { auth_headers(user) }

  def json_body = JSON.parse(response.body)

  describe "GET /api/v1/diary_entries" do
    it "returns diary entries" do
      create(:diary_entry, baby: baby, user: user, content: "A wonderful day")
      create(:diary_entry, baby: baby, user: user, content: "So much fun")

      get "/api/v1/diary_entries", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(2)
    end

    it "filters by mood" do
      create(:diary_entry, baby: baby, user: user, mood: "happy")
      create(:diary_entry, baby: baby, user: user, mood: "sad")

      get "/api/v1/diary_entries", params: { mood: "happy" }, headers: headers
      expect(json_body["data"].length).to eq(1)
    end
  end

  describe "POST /api/v1/diary_entries" do
    it "creates a diary entry" do
      post "/api/v1/diary_entries",
        params: { diary_entry: { content: "First giggle!", entry_date: "2026-06-15", mood: "funny" } },
        headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["content"]).to eq("First giggle!")
      expect(json_body["data"]["mood"]).to eq("funny")
      expect(json_body["data"]["age_days"]).to eq(98)
    end
  end

  describe "PATCH /api/v1/diary_entries/:id" do
    it "updates a diary entry" do
      d = create(:diary_entry, baby: baby, user: user)
      patch "/api/v1/diary_entries/#{d.id}", params: { diary_entry: { content: "Updated content" } }, headers: headers, as: :json
      expect(json_body["data"]["content"]).to eq("Updated content")
    end
  end

  describe "DELETE /api/v1/diary_entries/:id" do
    it "deletes a diary entry" do
      d = create(:diary_entry, baby: baby, user: user)
      delete "/api/v1/diary_entries/#{d.id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end
  end
end
