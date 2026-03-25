FactoryBot.define do
  factory :milk_stash_log do
    milk_stash
    user
    action { "consumed" }
    volume_ml { 50 }
  end
end
