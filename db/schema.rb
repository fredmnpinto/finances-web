# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_19_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_categories_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "transactions", id: :serial, force: :cascade do |t|
    t.decimal "amount", null: false
    t.decimal "balance"
    t.bigint "category_id"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.date "date", null: false
    t.text "description", null: false
    t.text "source_file"
    t.bigint "suggested_category_id"
    t.integer "transaction_type"
    t.bigint "user_id", null: false
    t.date "value_date"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["suggested_category_id"], name: "index_transactions_on_suggested_category_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
    t.unique_constraint ["date", "description", "amount", "balance"], name: "transactions_date_description_amount_balance_key"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "categories", "users"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "categories", column: "suggested_category_id"
  add_foreign_key "transactions", "users"
end
