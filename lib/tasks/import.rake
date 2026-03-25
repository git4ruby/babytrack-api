namespace :import do
  desc "Import historical feeding data from iPhone Notes (March 11-24, 2026)"
  task feedings: :environment do
    load Rails.root.join("db/seeds/import_historical_feedings.rb")
  end
end
