class AddConfirmedCategoryToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :confirmed_category, :text
    add_column :transactions, :confirmed_category_at, :datetime
  end
end
