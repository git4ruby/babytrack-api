source "https://rubygems.org"

gem "rails", "~> 8.0.4"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false

# Authentication
gem "devise", "~> 4.9"
gem "devise-jwt", "~> 0.12"

# Background jobs
gem "sidekiq", "~> 7.3"
gem "sidekiq-scheduler", "~> 5.0"
gem "connection_pool", "~> 2.4"

# API
gem "rack-cors"
gem "kaminari"
gem "rack-attack"

# Twilio SMS
gem "twilio-ruby", "~> 7.0"

# Gmail polling
gem "net-imap"
gem "mail"

# Soft delete
gem "discard", "~> 1.3"

# PDF generation
gem "prawn", "~> 2.5"
gem "prawn-table", "~> 0.2"

# Error tracking
gem "sentry-ruby", "~> 5.22"
gem "sentry-rails", "~> 5.22"
gem "sentry-sidekiq", "~> 5.22"

# Environment variables
gem "dotenv-rails"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
end
