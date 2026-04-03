require 'rails_helper'

RSpec.describe "Api::V1::BabyShares", type: :request do
  let!(:user) { create(:user) }
  let!(:baby) { create(:baby, user: user) }
  let(:headers) { auth_headers(user) }

  def json_body
    JSON.parse(response.body)
  end

  describe "POST /api/v1/baby_shares" do
    it "creates a share invite by email" do
      params = { email: "caregiver@example.com", role: "caregiver" }

      post "/api/v1/baby_shares", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["invite_email"]).to eq("caregiver@example.com")
      expect(json_body["data"]["role"]).to eq("caregiver")
      expect(json_body["data"]["status"]).to eq("pending")
    end

    it "creates a viewer share" do
      params = { email: "viewer@example.com", role: "viewer" }

      post "/api/v1/baby_shares", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["role"]).to eq("viewer")
    end

    it "links existing user when email matches" do
      existing_user = create(:user, email: "existing@example.com")
      params = { email: "existing@example.com" }

      post "/api/v1/baby_shares", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      share = BabyShare.last
      expect(share.user).to eq(existing_user)
    end

    it "downcases and strips email" do
      params = { email: "  Caregiver@Example.COM  " }

      post "/api/v1/baby_shares", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["invite_email"]).to eq("caregiver@example.com")
    end

    it "returns errors for missing email" do
      params = { email: "" }

      post "/api/v1/baby_shares", params: params, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"]).to be_present
    end

    it "sends an invite email" do
      params = { email: "caregiver@example.com" }

      expect {
        post "/api/v1/baby_shares", params: params, headers: headers, as: :json
      }.to have_enqueued_mail(ShareMailer, :invite)
    end
  end

  describe "POST /api/v1/baby_shares/accept" do
    it "accepts an invite for a logged-in user" do
      share = create(:baby_share, baby: baby, invite_email: user.email)
      accepting_user = create(:user)
      accepting_headers = auth_headers(accepting_user)

      post "/api/v1/baby_shares/accept",
        params: { token: share.invite_token },
        headers: accepting_headers, as: :json

      expect(response).to have_http_status(:ok)
      share.reload
      expect(share).to be_accepted
      expect(share.user).to eq(accepting_user)
      expect(share.accepted_at).to be_present
    end

    it "returns not found for invalid token" do
      post "/api/v1/baby_shares/accept",
        params: { token: "invalid_token" }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(json_body["error"]).to eq("Invalid or expired invite link")
    end

    it "returns message when already accepted" do
      share = create(:baby_share, :accepted, baby: baby)

      post "/api/v1/baby_shares/accept",
        params: { token: share.invite_token },
        headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["message"]).to eq("Invite already accepted")
    end

    it "returns invite data when user is not logged in" do
      share = create(:baby_share, baby: baby, invite_email: "new@example.com")

      post "/api/v1/baby_shares/accept",
        params: { token: share.invite_token }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["invite_email"]).to eq("new@example.com")
      expect(json_body["data"]["baby_name"]).to eq(baby.name)
      expect(json_body["data"]["token"]).to eq(share.invite_token)
    end
  end

  describe "GET /api/v1/baby_shares" do
    it "lists all shares for the baby" do
      create(:baby_share, baby: baby)
      create(:baby_share, :accepted, baby: baby)

      get "/api/v1/baby_shares", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(2)
    end

    it "returns 401 without auth" do
      get "/api/v1/baby_shares"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/baby_shares/:id" do
    it "revokes a share" do
      share = create(:baby_share, baby: baby)

      delete "/api/v1/baby_shares/#{share.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["message"]).to eq("Access revoked")
      expect(BabyShare.find_by(id: share.id)).to be_nil
    end
  end
end
