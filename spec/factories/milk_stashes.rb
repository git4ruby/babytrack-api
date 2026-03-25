FactoryBot.define do
  factory :milk_stash do
    baby
    user
    volume_ml { 100 }
    remaining_ml { 100 }
    storage_type { "fridge" }
    status { "available" }
    source_type { "pumped" }
    stored_at { Time.current }
    expires_at { Time.current + 96.hours }

    trait :in_fridge do
      storage_type { "fridge" }
      expires_at { Time.current + 96.hours }
    end

    trait :in_freezer do
      storage_type { "freezer" }
      expires_at { Time.current + 4320.hours }
    end

    trait :at_room_temp do
      storage_type { "room_temp" }
      expires_at { Time.current + 4.hours }
    end

    trait :expiring_soon do
      storage_type { "fridge" }
      expires_at { Time.current + 2.hours }
    end

    trait :expired do
      storage_type { "fridge" }
      stored_at { 5.days.ago }
      expires_at { 1.day.ago }
    end

    trait :partially_consumed do
      volume_ml { 100 }
      remaining_ml { 40 }
    end

    trait :fully_consumed do
      volume_ml { 100 }
      remaining_ml { 0 }
      status { "consumed" }
    end

    trait :discarded_stash do
      volume_ml { 100 }
      remaining_ml { 0 }
      status { "discarded" }
    end

    trait :labeled do
      label { "Morning pump #{Date.current}" }
    end
  end
end
