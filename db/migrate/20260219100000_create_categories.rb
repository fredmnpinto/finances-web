class CreateCategories < ActiveRecord::Migration[8.1]
  def up
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color
      t.string :icon
      t.timestamps
    end

    add_index :categories, [ :user_id, :name ], unique: true

    add_reference :transactions, :category, foreign_key: true
    add_reference :transactions, :suggested_category, foreign_key: { to_table: :categories }

    remove_column :transactions, :suggested_category
    remove_column :transactions, :confirmed_category
    remove_column :transactions, :confirmed_category_at
    remove_column :transactions, :category_confidence
    remove_column :transactions, :category_source
  end

  def down
    add_column :transactions, :suggested_category, :string
    add_column :transactions, :confirmed_category, :string
    add_column :transactions, :confirmed_category_at, :datetime
    add_column :transactions, :category_confidence, :decimal
    add_column :transactions, :category_source, :text

    remove_reference :transactions, :suggested_category, foreign_key: { to_table: :categories }
    remove_reference :transactions, :category, foreign_key: true

    drop_table :categories
  end
end
