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

ActiveRecord::Schema[7.2].define(version: 2026_04_19_000001) do
  create_table "employees", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "job_title", null: false
    t.string "country", limit: 2, null: false
    t.decimal "salary", precision: 12, scale: 2, null: false
    t.string "currency", limit: 3, null: false
    t.integer "department_id"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_employees_on_country"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["full_name"], name: "index_employees_on_full_name", type: :fulltext
    t.index ["job_title"], name: "index_employees_on_job_title"
    t.index ["salary", "country"], name: "index_employees_on_salary_and_country"
  end

  create_table "versions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :long
    t.text "object_changes", size: :long
    t.string "current_ip"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end
end
