require 'rails_helper'

RSpec.describe "Api::V1::Milestones", type: :request do
  let!(:user) { create(:user) }
  let!(:baby) { create(:baby, user: user) }
  let(:headers) { auth_headers(user) }

  def json_body = JSON.parse(response.body)

  describe "GET /api/v1/milestones" do
    it "returns milestones" do
      create(:milestone, baby: baby, user: user, title: "First smile")
      create(:milestone, baby: baby, user: user, title: "First roll", category: "motor")

      get "/api/v1/milestones", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(2)
    end

    it "filters by category" do
      create(:milestone, baby: baby, user: user, category: "motor")
      create(:milestone, baby: baby, user: user, category: "social")

      get "/api/v1/milestones", params: { category: "motor" }, headers: headers
      expect(json_body["data"].length).to eq(1)
    end
  end

  describe "POST /api/v1/milestones" do
    it "creates a milestone" do
      post "/api/v1/milestones",
        params: { milestone: { title: "First word", achieved_on: "2026-06-15", category: "language", description: "Said mama!" } },
        headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["title"]).to eq("First word")
      expect(json_body["data"]["age_days"]).to eq(98)
    end
  end

  describe "PATCH /api/v1/milestones/:id" do
    it "updates a milestone" do
      m = create(:milestone, baby: baby, user: user)
      patch "/api/v1/milestones/#{m.id}", params: { milestone: { title: "Updated" } }, headers: headers, as: :json
      expect(json_body["data"]["title"]).to eq("Updated")
    end
  end

  describe "DELETE /api/v1/milestones/:id" do
    it "deletes a milestone" do
      m = create(:milestone, baby: baby, user: user)
      delete "/api/v1/milestones/#{m.id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end
  end
end
