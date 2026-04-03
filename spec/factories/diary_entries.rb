FactoryBot.define do
  factory :diary_entry do
    baby
    user
    content { "Baby laughed for the first time today!" }
    entry_date { Date.current }
    mood { "happy" }
  end
end
