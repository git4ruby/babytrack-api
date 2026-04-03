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
    key = "photos/#{SecureRandom.uuid}#{ext}"

    if r2_configured?
      upload_to_r2(key, file)
      url = "#{ENV.fetch('R2_PUBLIC_URL')}/#{key}"
    else
      upload_locally(key, file)
      url = "/uploads/#{key}"
    end

    render json: { url: url }, status: :created
  end

  private

  def r2_configured?
    ENV["R2_ACCESS_KEY_ID"].present? && ENV["R2_BUCKET"].present?
  end

  def r2_client
    @r2_client ||= Aws::S3::Client.new(
      region: "auto",
      endpoint: ENV.fetch("R2_ENDPOINT"),
      access_key_id: ENV.fetch("R2_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("R2_SECRET_ACCESS_KEY"),
      force_path_style: true
    )
  end

  def upload_to_r2(key, file)
    r2_client.put_object(
      bucket: ENV.fetch("R2_BUCKET"),
      key: key,
      body: file.read,
      content_type: file.content_type
    )
  end

  def upload_locally(key, file)
    dest = Rails.root.join("public", "uploads", key)
    FileUtils.mkdir_p(File.dirname(dest))
    File.binwrite(dest, file.read)
  end
end
