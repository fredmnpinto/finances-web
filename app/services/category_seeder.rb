class CategorySeeder
  DEFAULT_CATEGORIES = [
    { name: 'Food', icon: '🍕' },
    { name: 'Transport', icon: '🚗' },
    { name: 'Housing', icon: '🏠' },
    { name: 'Entertainment', icon: '🎬' },
    { name: 'Shopping', icon: '🛒' },
    { name: 'Utilities', icon: '💡' },
    { name: 'Health', icon: '🏥' },
    { name: 'Income', icon: '💰' },
    { name: 'Savings', icon: '💎' }
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
        category.icon = attrs[:icon]
      end
    end
  end
end
