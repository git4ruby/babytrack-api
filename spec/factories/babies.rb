FactoryBot.define do
  factory :baby do
    name { "Test Baby" }
    date_of_birth { Date.new(2026, 3, 9) }
    gender { "male" }
    birth_weight_grams { 3200 }
  end
end
