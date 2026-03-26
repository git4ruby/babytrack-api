class InboundMessageJob < ApplicationJob
  queue_as :default

  def perform(user_id:, message:, source: "sms")
    user = User.find(user_id)

    results = Inbound::MessageProcessorService.new(
      user: user,
      message_text: message,
      source: source
    ).process

    results.each do |r|
      if r[:success]
        Rails.logger.info("Inbound #{source}: Created #{r[:type]} for user #{user.id}")
      else
        Rails.logger.warn("Inbound #{source}: Failed — #{r[:message]}")
      end
    end
  end
end
