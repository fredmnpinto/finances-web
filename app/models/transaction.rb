class Transaction < ApplicationRecord
  enum :transaction_type, { expense: 0, income: 1, savings: 2 }
end
