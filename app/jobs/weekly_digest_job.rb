class WeeklyDigestJob < ApplicationJob
  queue_as :default

  def perform
    Time.use_zone("Eastern Time (US & Canada)") do
      to_date = Date.current - 1  # Yesterday (Sunday)
      from_date = to_date - 6     # Previous Monday

      User.includes(:babies, :shared_babies).find_each do |user|
        babies = (user.babies + user.shared_babies).uniq
        next if babies.empty?
        next if user.email.blank?

        babies.each do |baby|
          stats = WeeklyDigestService.new(baby, from_date, to_date).call
          WeeklyDigestMailer.digest(user, baby, stats, from_date, to_date).deliver_later
        end

        Rails.logger.info("Sent weekly digest to #{user.email} for #{babies.map(&:name).join(', ')}")
      end
    end
  end
end
