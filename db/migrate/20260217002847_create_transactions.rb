class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    return if table_exists?(:transactions)

    create_table :transactions do |t|
      t.decimal :amount, null: false
      t.decimal :balance
      t.float :category_confidence
      t.text :category_source
      t.text :confirmed_category
      t.datetime :confirmed_category_at
      t.date :date, null: false
      t.text :description, null: false
      t.text :source_file
      t.text :suggested_category
      t.integer :transaction_type
      t.bigint :user_id, null: false
      t.date :value_date

      t.timestamps
    end

    add_index :transactions, :user_id
    add_unique_constraint :transactions, [ :date, :description, :amount, :balance ], name: 'transactions_date_description_amount_balance_key'
  end
end
