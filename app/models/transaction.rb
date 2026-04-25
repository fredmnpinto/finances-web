class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :suggested_category, class_name: "Category", optional: true

  enum :transaction_type, { expense: 0, income: 1, savings: 2 }

  validates :user, presence: true
  validates :amount, presence: true, numericality: true
  validates :description, presence: true
  validates :transaction_date, presence: true
  validates :transaction_type, presence: true
end
