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

ActiveRecord::Schema[8.1].define(version: 2026_01_29_231232) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "transactions", id: :serial, force: :cascade do |t|
    t.decimal "amount", null: false
    t.decimal "balance"
    t.float "category_confidence", limit: 24
    t.text "category_source"
    t.text "confirmed_category"
    t.datetime "confirmed_category_at", precision: nil
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.date "date", null: false
    t.text "description", null: false
    t.text "source_file"
    t.text "suggested_category"
    t.integer "transaction_type"
    t.date "value_date"

    t.unique_constraint ["date", "description", "amount", "balance"], name: "transactions_date_description_amount_balance_key"
  end
end
