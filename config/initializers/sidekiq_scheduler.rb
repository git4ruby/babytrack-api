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
        },
        "appointment_reminders" => {
          "every" => "15m",
          "class" => "AppointmentReminderJob",
          "queue" => "default",
          "description" => "Send appointment reminders 24h before"
        },
        "vaccination_alerts" => {
          "every" => "24h",
          "first_at" => "09:00",
          "class" => "VaccinationAlertJob",
          "queue" => "default",
          "description" => "Daily check for vaccines due within 7 days"
        }
      }

      SidekiqScheduler::Scheduler.instance.reload_schedule!
    end
  end
end
