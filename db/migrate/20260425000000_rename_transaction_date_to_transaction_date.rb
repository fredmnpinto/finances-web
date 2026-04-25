class RenameTransactionDateToTransactionDate < ActiveRecord::Migration[8.1]
  def change
    rename_column :transactions, :date, :transaction_date
  end
end
