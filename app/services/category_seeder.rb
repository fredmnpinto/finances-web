class CategorySeeder
  DEFAULT_CATEGORIES = [
    { name: "Salary", group: :income },
    { name: "Freelance", group: :income },
    { name: "Investments", group: :income },
    { name: "Refunds", group: :income },
    { name: "Other Income", group: :income },
    { name: "Housing", group: :needs },
    { name: "Food", group: :needs },
    { name: "Transport", group: :needs },
    { name: "Utilities", group: :needs },
    { name: "Health", group: :needs },
    { name: "Insurance", group: :needs },
    { name: "Entertainment", group: :wants },
    { name: "Shopping", group: :wants },
    { name: "Self-care", group: :wants },
    { name: "Subscriptions", group: :wants },
    { name: "Savings", group: :savings },
    { name: "Other Savings", group: :savings },
    { name: "Other Expenses", group: :needs },
  ].freeze

  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
  end

  def call
    DEFAULT_CATEGORIES.each do |attrs|
      @user.categories.find_or_create_by!(name: attrs[:name]) do |category|
        category.category_group = attrs[:group]
      end
    end
  end
end
