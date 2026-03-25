FactoryBot.define do
  factory :weight_log do
    baby
    user
    recorded_at { Date.current }
    weight_grams { 3500 }
    measured_by { "Home scale" }
  end
end
