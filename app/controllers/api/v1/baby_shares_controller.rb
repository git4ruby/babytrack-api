class Api::V1::BabySharesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :accept ]

  # GET /api/v1/baby_shares
  def index
    shares = current_baby.baby_shares.includes(:user).order(:created_at)
    render json: {
      data: shares.map { |s| share_json(s) }
    }
  end

  # POST /api/v1/baby_shares — invite someone
  def create
    share = current_baby.baby_shares.build(
      invite_email: params[:email]&.downcase&.strip,
      role: params[:role] || "caregiver"
    )

    # If user already exists, link immediately
    existing_user = User.find_by(email: share.invite_email)
    if existing_user
      share.user = existing_user
    end

    if share.save
      ShareMailer.invite(share, current_user, current_baby).deliver_later
      render json: { data: share_json(share) }, status: :created
    else
      render json: { errors: share.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/baby_shares/accept?token=
  def accept
    share = BabyShare.find_by(invite_token: params[:token])

    unless share
      render json: { error: "Invalid or expired invite link" }, status: :not_found
      return
    end

    if share.accepted?
      render json: { message: "Invite already accepted" }
      return
    end

    # If user is logged in, link to them
    if current_user
      share.update!(user: current_user, status: "accepted", accepted_at: Time.current)
      render json: { message: "You now have access to #{share.baby.name}" }
    else
      # Not logged in — redirect to signup with token
      render json: { data: { invite_email: share.invite_email, baby_name: share.baby.name, token: share.invite_token } }
    end
  end

  # DELETE /api/v1/baby_shares/:id
  def destroy
    share = current_baby.baby_shares.find(params[:id])
    share.destroy
    render json: { message: "Access revoked" }
  end

  private

  def share_json(share)
    {
      id: share.id,
      invite_email: share.invite_email,
      role: share.role,
      status: share.status,
      user_name: share.user&.name,
      accepted_at: share.accepted_at,
      created_at: share.created_at
    }
  end
end
