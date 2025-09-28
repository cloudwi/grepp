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

ActiveRecord::Schema[8.0].define(version: 2025_09_28_080100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "course_registrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at", precision: nil
    t.index ["course_id", "created_at"], name: "idx_course_reg_course_created"
    t.index ["course_id"], name: "index_course_registrations_on_course_id"
    t.index ["user_id", "completed_at"], name: "idx_course_reg_user_completed"
    t.index ["user_id", "course_id"], name: "idx_course_reg_pending", where: "(completed_at IS NULL)"
    t.index ["user_id", "course_id"], name: "idx_course_reg_user_course", unique: true
    t.index ["user_id"], name: "index_course_registrations_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title"
    t.datetime "enrollment_start_date"
    t.datetime "enrollment_end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "registrations_count", default: 0, null: false
    t.index "to_tsvector('simple'::regconfig, (COALESCE(title, ''::character varying))::text)", name: "idx_courses_title_search", using: :gin
    t.index ["created_at"], name: "index_courses_on_created_at"
    t.index ["enrollment_end_date"], name: "index_courses_on_enrollment_end_date"
    t.index ["enrollment_start_date", "enrollment_end_date", "created_at"], name: "idx_courses_status_created"
    t.index ["enrollment_start_date", "enrollment_end_date", "title"], name: "idx_courses_status_title"
    t.index ["enrollment_start_date", "enrollment_end_date"], name: "index_courses_on_enrollment_start_date_and_enrollment_end_date"
    t.index ["enrollment_start_date"], name: "index_courses_on_enrollment_start_date"
    t.index ["price"], name: "idx_courses_price"
    t.index ["registrations_count", "created_at"], name: "idx_courses_popularity_created"
    t.index ["registrations_count"], name: "idx_courses_registrations_count"
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
    t.index ["cancelled_at"], name: "idx_payments_cancelled_at"
    t.index ["payable_type", "payable_id"], name: "index_payments_on_payable"
    t.index ["payment_time"], name: "idx_payments_payment_time"
    t.index ["status"], name: "idx_payments_status"
    t.index ["user_id", "created_at"], name: "idx_payments_active", where: "((status)::text = ANY ((ARRAY['completed'::character varying, 'pending'::character varying])::text[]))"
    t.index ["user_id", "payment_time"], name: "idx_payments_user_time"
    t.index ["user_id", "status"], name: "idx_payments_user_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "test_registrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "test_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at", precision: nil
    t.index ["test_id", "created_at"], name: "idx_test_reg_test_created"
    t.index ["test_id"], name: "index_test_registrations_on_test_id"
    t.index ["user_id", "completed_at"], name: "idx_test_reg_user_completed"
    t.index ["user_id", "test_id"], name: "idx_test_reg_pending", where: "(completed_at IS NULL)"
    t.index ["user_id", "test_id"], name: "idx_test_reg_user_test", unique: true
    t.index ["user_id"], name: "index_test_registrations_on_user_id"
  end

  create_table "tests", force: :cascade do |t|
    t.string "title"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "registrations_count", default: 0, null: false
    t.index "to_tsvector('simple'::regconfig, (COALESCE(title, ''::character varying))::text)", name: "idx_tests_title_search", using: :gin
    t.index ["created_at"], name: "index_tests_on_created_at"
    t.index ["end_date"], name: "index_tests_on_end_date"
    t.index ["price"], name: "idx_tests_price"
    t.index ["registrations_count", "created_at"], name: "idx_tests_popularity_created"
    t.index ["registrations_count"], name: "idx_tests_registrations_count"
    t.index ["start_date", "end_date", "created_at"], name: "idx_tests_status_created"
    t.index ["start_date", "end_date", "title"], name: "idx_tests_status_title"
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
