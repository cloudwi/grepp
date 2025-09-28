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

ActiveRecord::Schema[8.0].define(version: 2025_09_28_055822) do
  create_table "course_registrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_registrations_on_course_id"
    t.index ["user_id"], name: "index_course_registrations_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title"
    t.datetime "enrollment_start_date"
    t.datetime "enrollment_end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_courses_on_created_at"
    t.index ["enrollment_end_date"], name: "index_courses_on_enrollment_end_date"
    t.index ["enrollment_start_date", "enrollment_end_date"], name: "index_courses_on_enrollment_start_date_and_enrollment_end_date"
    t.index ["enrollment_start_date"], name: "index_courses_on_enrollment_start_date"
    t.index ["title"], name: "index_courses_on_title"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount"
    t.string "payment_method"
    t.string "status"
    t.datetime "payment_time"
    t.datetime "cancelled_at"
    t.integer "user_id", null: false
    t.string "payable_type", null: false
    t.integer "payable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payable_type", "payable_id"], name: "index_payments_on_payable"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "test_registrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "test_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["test_id"], name: "index_test_registrations_on_test_id"
    t.index ["user_id"], name: "index_test_registrations_on_user_id"
  end

  create_table "tests", force: :cascade do |t|
    t.string "title"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tests_on_created_at"
    t.index ["end_date"], name: "index_tests_on_end_date"
    t.index ["start_date", "end_date"], name: "index_tests_on_start_date_and_end_date"
    t.index ["start_date"], name: "index_tests_on_start_date"
    t.index ["title"], name: "index_tests_on_title"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "course_registrations", "courses"
  add_foreign_key "course_registrations", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "test_registrations", "tests"
  add_foreign_key "test_registrations", "users"
end
