class AddGroupToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :category_group, :integer, null: false, default: 0
  end
end
