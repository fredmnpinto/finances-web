class AddTransactionTypeToTransactions < ActiveRecord::Migration[8.1]
  def up
    add_column :transactions, :transaction_type, :integer

    return unless column_exists?(:transactions, :confirmed_category)
    return unless column_exists?(:transactions, :suggested_category)

    execute <<~SQL
      UPDATE transactions
      SET transaction_type = 0
      WHERE amount < 0;

      UPDATE transactions
      SET transaction_type = 2
      WHERE COALESCE(confirmed_category, suggested_category) = 'Savings';

      UPDATE transactions
      SET transaction_type = 1
      WHERE amount > 0
      AND COALESCE(confirmed_category, suggested_category) != 'Savings';
    SQL
  end

  def down
    remove_column :transactions, :transaction_type
  end
end
