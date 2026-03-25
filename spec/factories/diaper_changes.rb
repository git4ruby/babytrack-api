FactoryBot.define do
  factory :diaper_change do
    baby
    user
    changed_at { Time.current }
    diaper_type { "wet" }

    trait :soiled do
      diaper_type { "soiled" }
      stool_color { "yellow" }
      consistency { "normal" }
    end

    trait :both do
      diaper_type { "both" }
      stool_color { "yellow" }
      consistency { "seedy" }
    end

    trait :with_rash do
      has_rash { true }
    end
  end
end
