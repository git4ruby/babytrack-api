if defined?(Sidekiq)
  Sidekiq.configure_server do |config|
    config.on(:startup) do
      SidekiqScheduler::Scheduler.instance.rufus_scheduler_options = { max_work_threads: 1 }

      Sidekiq.schedule = {
        "gmail_poll" => {
          "every" => "1m",
          "class" => "GmailPollJob",
          "queue" => "default",
          "description" => "Poll Gmail inbox for inbound messages"
        }
      }

      SidekiqScheduler::Scheduler.instance.reload_schedule!
    end
  end
end
