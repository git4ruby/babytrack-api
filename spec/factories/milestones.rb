FactoryBot.define do
  factory :milestone do
    baby
    user
    title { "First smile" }
    achieved_on { Date.current }
    category { "social" }
  end
end
