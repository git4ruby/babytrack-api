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

    ext = File.extname(file.original_filename).downcase
    ext = ".jpg" unless %w[.jpg .jpeg .png .gif .webp].include?(ext)
    filename = "#{SecureRandom.uuid}#{ext}"

    upload_dir = Rails.root.join("public", "uploads", "milestones")
    FileUtils.mkdir_p(upload_dir)
    File.open(upload_dir.join(filename), "wb") { |f| f.write(file.read) }

    url = "/uploads/milestones/#{filename}"
    render json: { url: url }, status: :created
  end
end
