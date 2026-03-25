FactoryBot.define do
  factory :feeding do
    baby
    user
    feed_type { "bottle" }
    started_at { Time.current }
    volume_ml { 60 }
    milk_type { "breast_milk" }

    trait :bottle do
      feed_type { "bottle" }
      volume_ml { 60 }
      milk_type { "breast_milk" }
    end

    trait :formula_bottle do
      feed_type { "bottle" }
      volume_ml { 80 }
      milk_type { "formula" }
      formula_brand { "Similac 360 Total Care" }
    end

    trait :breastfeed do
      feed_type { "breastfeed" }
      volume_ml { nil }
      milk_type { nil }
      breast_side { "left" }
      started_at { 30.minutes.ago }
      ended_at { Time.current }
    end

    trait :pump do
      feed_type { "pump" }
      volume_ml { 100 }
      milk_type { "breast_milk" }
    end

    trait :combo do
      session_group { SecureRandom.uuid }
    end
  end
end
