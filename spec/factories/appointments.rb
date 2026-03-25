FactoryBot.define do
  factory :appointment do
    baby
    user
    title { "2-month well visit" }
    appointment_type { "well_visit" }
    scheduled_at { 1.week.from_now }
    location { "Children's Hospital" }
    provider_name { "Dr. Smith" }
    status { "upcoming" }
  end
end
