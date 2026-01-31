# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :user do
    first_name { "John" }
    last_name { "Doe" }
    email { "john.doe#{SecureRandom.hex(4)}@example.com" }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :admin do
      first_name { "Admin" }
      email { "admin@finances-web.local" }
    end
  end
end
