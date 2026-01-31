# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :transaction do
    amount { -50.00 }
    description { Faker::Restaurant.name }
    date { Date.current }
    value_date { Date.current }
    balance { 1000.00 }
    confirmed_category { "Eating Out" }
    suggested_category { "Eating Out" }
    category_confidence { 0.95 }
    source_file { "import.csv" }
    transaction_type { "expense" }

    association :user

    trait :income do
      amount { 2000.00 }
      description { "Salary" }
      confirmed_category { "Salary" }
      suggested_category { "Salary" }
      transaction_type { "income" }
    end

    trait :savings do
      amount { -500.00 }
      description { "Emergency fund" }
      confirmed_category { "Savings" }
      suggested_category { "Savings" }
      transaction_type { "savings" }
    end

    trait :uncategorized do
      confirmed_category { nil }
      suggested_category { "Uncategorized" }
      category_confidence { 0.0 }
    end
  end
end
