class InboundConfirmationMailer < ApplicationMailer
  def log_confirmation(user:, baby:, results:, source:, original_message:)
    @user = user
    @baby = baby
    @results = results
    @source = source
    @original_message = original_message
    @success_count = results.count { |r| r[:success] }
    @fail_count = results.count { |r| !r[:success] }

    mail(
      to: user.email,
      subject: "BabyTrack: #{@success_count} record(s) logged for #{baby.name}"
    )
  end
end
