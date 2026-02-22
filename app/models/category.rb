class Category < ApplicationRecord
  enum :category_group, { needs: 0, wants: 1, savings: 2, income: 3 }, default: :needs

  belongs_to :user
  has_many :transactions, foreign_key: 'category_id', dependent: :nullify
  has_many :suggested_transactions, class_name: 'Transaction', foreign_key: 'suggested_category_id', dependent: :nullify

  validates :name, presence: true
  validates :user_id, uniqueness: { scope: :name }

  before_validation :set_random_color, on: :create, if: -> { color.blank? }

  COLORS = %w[
    #EF4444 #F97316 #F59E0B #84CC16 #22C55E #10B981
    #14B8A6 #06B6D4 #0EA5E9 #3B82F6 #6366F1 #8B5CF6
    #A855F7 #D946EF #EC4899 #F43F5E
  ].freeze

  private

  def set_random_color
    self.color = COLORS.sample
  end
end
