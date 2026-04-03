FactoryBot.define do
  factory :sleep_log do
    baby
    user
    sleep_type { "nap" }
    started_at { 2.hours.ago }
    ended_at { 1.hour.ago }
    duration_minutes { 60 }
    location { "crib" }

    trait :nap do
      sleep_type { "nap" }
      started_at { 2.hours.ago }
      ended_at { 1.hour.ago }
    end

    trait :night do
      sleep_type { "night" }
      started_at { 10.hours.ago }
      ended_at { 2.hours.ago }
      duration_minutes { 480 }
    end

    trait :no_end do
      ended_at { nil }
      duration_minutes { nil }
    end
  end
end
