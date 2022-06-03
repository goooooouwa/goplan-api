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

ActiveRecord::Schema[7.0].define(version: 2022_06_03_081641) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.datetime "target_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "todo_children", force: :cascade do |t|
    t.bigint "todo_id", null: false
    t.bigint "child_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_todo_children_on_child_id"
    t.index ["todo_id"], name: "index_todo_children_on_todo_id"
  end

  create_table "todos", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name"
    t.text "description"
    t.float "time_span"
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean "repeat"
    t.string "repeat_period"
    t.integer "repeat_times"
    t.integer "instance_time_span"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "status", default: false
    t.index ["project_id"], name: "index_todos_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "todo_children", "todos"
  add_foreign_key "todo_children", "todos", column: "child_id"
  add_foreign_key "todos", "projects"
end
