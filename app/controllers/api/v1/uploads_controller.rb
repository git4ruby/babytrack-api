class Api::V1::UploadsController < ApplicationController
  # POST /api/v1/uploads
  def create
    file = params[:file]
    unless file.is_a?(ActionDispatch::Http::UploadedFile)
      return render json: { error: "No file provided" }, status: :unprocessable_entity
    end

    unless file.content_type.start_with?("image/")
      return render json: { error: "Only image files allowed" }, status: :unprocessable_entity
    end

    if file.size > 5.megabytes
      return render json: { error: "File too large (max 5MB)" }, status: :unprocessable_entity
    end

    allowed_exts = { ".jpg" => ".jpg", ".jpeg" => ".jpeg", ".png" => ".png", ".gif" => ".gif", ".webp" => ".webp" }
    raw_ext = File.extname(file.original_filename).downcase
    ext = allowed_exts.fetch(raw_ext, ".jpg")
    filename = "#{SecureRandom.uuid}#{ext}"

    upload_dir = Rails.root.join("public", "uploads", "milestones")
    FileUtils.mkdir_p(upload_dir)
    dest = upload_dir.join(filename)
    File.binwrite(dest, file.read) # rubocop:disable Rails/SaveBang

    url = "/uploads/milestones/#{filename}"
    render json: { url: url }, status: :created
  end
end
