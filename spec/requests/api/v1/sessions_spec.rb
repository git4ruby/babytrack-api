require 'rails_helper'

RSpec.describe "Api::V1::Sessions", type: :request do
  let!(:user) { create(:user, email: "test@example.com", password: "password123") }

  describe "POST /api/v1/auth/sign_in" do
    it "returns a JWT token on successful login" do
      post "/api/v1/auth/sign_in", params: {
        user: { email: "test@example.com", password: "password123" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to be_present
      expect(json_body["data"]["email"]).to eq("test@example.com")
    end

    it "returns 401 on invalid credentials" do
      post "/api/v1/auth/sign_in", params: {
        user: { email: "test@example.com", password: "wrong" }
      }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    it "revokes the JWT token" do
      delete "/api/v1/auth/sign_out", headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  private

  def json_body
    JSON.parse(response.body)
  end
end
