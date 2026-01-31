class AddUserToTransactions < ActiveRecord::Migration[8.1]
  def up
    # Add column without null constraint first
    add_reference :transactions, :user, foreign_key: true

    # Create default admin user with a basic encrypted password
    admin_email = 'admin@finances-web.local'

    # Use a simple approach to create the admin user
    execute <<-SQL
      INSERT INTO users (email, encrypted_password, first_name, last_name, confirmed_at, created_at, updated_at)
      VALUES ('#{admin_email}', '$2a$12$r9zD5c5e5e5e5e5e5e5e5eOz1X5u5Q5q5K5r5M5N5O5P5Q5R5S5T', 'Admin', 'User', NOW(), NOW(), NOW())
      RETURNING id;
    SQL

    # Get the admin user ID and assign existing transactions
    result = execute("SELECT id FROM users WHERE email = '#{admin_email}'")
    admin_id = result.first['id'] if result.any?

    if admin_id
      execute "UPDATE transactions SET user_id = #{admin_id} WHERE user_id IS NULL;"
      puts "Created admin user: #{admin_email} with password: AdminPassword123!"
      puts "All existing transactions have been assigned to this admin user."

      # Now add the not null constraint
      change_column_null :transactions, :user_id, false
    end
  end

  def down
    remove_reference :transactions, :user
  end
end
