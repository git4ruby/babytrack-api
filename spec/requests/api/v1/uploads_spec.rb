require 'rails_helper'

RSpec.describe "Api::V1::Uploads", type: :request do
  let!(:user) { create(:user) }
  let!(:baby) { create(:baby, user: user) }
  let(:headers) { auth_headers(user) }

  def json_body
    JSON.parse(response.body)
  end

  describe "POST /api/v1/uploads" do
    it "uploads an image successfully" do
      file = Rack::Test::UploadedFile.new(
        StringIO.new("fake image data"),
        "image/jpeg",
        true,
        original_filename: "photo.jpg"
      )

      post "/api/v1/uploads", params: { file: file }, headers: headers

      expect(response).to have_http_status(:created)
      expect(json_body["url"]).to match(%r{/uploads/milestones/.+\.jpg})
    end

    it "uploads a PNG image" do
      file = Rack::Test::UploadedFile.new(
        StringIO.new("fake png data"),
        "image/png",
        true,
        original_filename: "screenshot.png"
      )

      post "/api/v1/uploads", params: { file: file }, headers: headers

      expect(response).to have_http_status(:created)
      expect(json_body["url"]).to match(%r{/uploads/milestones/.+\.png})
    end

    it "rejects non-image files" do
      file = Rack::Test::UploadedFile.new(
        StringIO.new("not an image"),
        "application/pdf",
        true,
        original_filename: "document.pdf"
      )

      post "/api/v1/uploads", params: { file: file }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["error"]).to eq("Only image files allowed")
    end

    it "rejects files over 5MB" do
      large_content = "x" * (5.megabytes + 1)
      file = Rack::Test::UploadedFile.new(
        StringIO.new(large_content),
        "image/jpeg",
        true,
        original_filename: "huge.jpg"
      )

      post "/api/v1/uploads", params: { file: file }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["error"]).to eq("File too large (max 5MB)")
    end

    it "returns error when no file provided" do
      post "/api/v1/uploads", params: {}, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["error"]).to eq("No file provided")
    end

    it "returns 401 without auth" do
      post "/api/v1/uploads"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
