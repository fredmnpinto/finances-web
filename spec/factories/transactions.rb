# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :category do
    name { Faker::Lorem.word }
    color { Category::COLORS.sample }
    category_group { Category.category_groups.keys.sample }

    association :user
  end

  factory :transaction do
    amount { -50.00 }
    description { Faker::Restaurant.name }
    date { Date.current }
    value_date { Date.current }
    balance { 1000.00 }
    source_file { "import.csv" }
    transaction_type { "expense" }

    association :user
    association :category

    trait :income do
      amount { 2000.00 }
      description { "Salary" }
      transaction_type { "income" }
    end

    trait :savings do
      amount { -500.00 }
      description { "Emergency fund" }
      transaction_type { "savings" }
    end

    trait :uncategorized do
      category { nil }
    end
  end
end
