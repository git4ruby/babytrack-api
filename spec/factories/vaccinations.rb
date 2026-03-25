FactoryBot.define do
  factory :vaccination do
    baby
    vaccine_name { "Hepatitis B — Dose 1" }
    recommended_age_days { 0 }
    status { "pending" }

    trait :administered do
      status { "administered" }
      administered_at { Date.current }
      administered_by { "Dr. Smith" }
      lot_number { "LOT123" }
    end
  end
end
