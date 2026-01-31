class Transaction < ApplicationRecord
  belongs_to :user

  enum :transaction_type, { expense: 0, income: 1, savings: 2 }

  validates :user, presence: true
end
