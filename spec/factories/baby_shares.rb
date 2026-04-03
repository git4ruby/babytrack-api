FactoryBot.define do
  factory :baby_share do
    baby
    user { nil }
    invite_email { Faker::Internet.unique.email }
    role { "caregiver" }
    status { "pending" }

    trait :accepted do
      user
      status { "accepted" }
      accepted_at { Time.current }
    end

    trait :viewer do
      role { "viewer" }
    end
  end
end
