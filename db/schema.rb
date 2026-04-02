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

ActiveRecord::Schema[8.0].define(version: 2026_04_02_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "appointments", force: :cascade do |t|
    t.bigint "baby_id", null: false
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "appointment_type", default: "well_visit", null: false
    t.datetime "scheduled_at", null: false
    t.string "location"
    t.string "provider_name"
    t.datetime "reminder_at"
    t.boolean "reminder_sent", default: false, null: false
    t.string "status", default: "upcoming", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["baby_id", "scheduled_at"], name: "index_appointments_on_baby_id_and_scheduled_at"
    t.index ["baby_id"], name: "index_appointments_on_baby_id"
    t.index ["reminder_at"], name: "index_appointments_on_reminder_at"
    t.index ["status"], name: "index_appointments_on_status"
    t.index ["user_id"], name: "index_appointments_on_user_id"
  end

  create_table "babies", force: :cascade do |t|
    t.string "name", null: false
    t.date "date_of_birth", null: false
    t.string "gender"
    t.integer "birth_weight_grams"
    t.decimal "birth_length_cm", precision: 5, scale: 2
    t.decimal "head_circumference_cm", precision: 5, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_babies_on_user_id"
  end

  create_table "diaper_changes", force: :cascade do |t|
    t.bigint "baby_id", null: false
    t.bigint "user_id", null: false
    t.datetime "changed_at"
    t.string "diaper_type", null: false
    t.string "stool_color"
    t.string "consistency"
    t.boolean "has_rash", default: false, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["baby_id", "changed_at"], name: "index_diaper_changes_on_baby_id_and_changed_at"
    t.index ["baby_id", "diaper_type"], name: "index_diaper_changes_on_baby_id_and_diaper_type"
    t.index ["baby_id"], name: "index_diaper_changes_on_baby_id"
    t.index ["user_id"], name: "index_diaper_changes_on_user_id"
  end

  create_table "feedings", force: :cascade do |t|
    t.bigint "baby_id", null: false
    t.bigint "user_id", null: false
    t.string "feed_type", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.integer "duration_minutes"
    t.integer "volume_ml"
    t.string "breast_side"
    t.string "milk_type"
    t.string "formula_brand"
    t.text "notes"
    t.uuid "session_group"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["baby_id", "started_at"], name: "index_feedings_on_baby_id_and_started_at"
    t.index ["baby_id"], name: "index_feedings_on_baby_id"
    t.index ["discarded_at"], name: "index_feedings_on_discarded_at"
    t.index ["feed_type"], name: "index_feedings_on_feed_type"
    t.index ["session_group"], name: "index_feedings_on_session_group"
    t.index ["user_id"], name: "index_feedings_on_user_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.bigint "baby_id", null: false
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.date "achieved_on", null: false
    t.string "category"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["baby_id", "achieved_on"], name: "index_milestones_on_baby_id_and_achieved_on"
    t.index ["baby_id", "category"], name: "index_milestones_on_baby_id_and_category"
    t.index ["baby_id"], name: "index_milestones_on_baby_id"
    t.index ["user_id"], name: "index_milestones_on_user_id"
  end

  create_table "milk_stash_logs", force: :cascade do |t|
    t.bigint "milk_stash_id", null: false
    t.bigint "user_id", null: false
    t.string "action", null: false
    t.integer "volume_ml", null: false
    t.string "destination_storage_type"
    t.bigint "feeding_id"
    t.string "reason"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feeding_id"], name: "index_milk_stash_logs_on_feeding_id"
    t.index ["milk_stash_id", "action"], name: "index_milk_stash_logs_on_milk_stash_id_and_action"
    t.index ["milk_stash_id"], name: "index_milk_stash_logs_on_milk_stash_id"
    t.index ["user_id"], name: "index_milk_stash_logs_on_user_id"
  end

  create_table "milk_stashes", force: :cascade do |t|
    t.bigint "baby_id", null: false
    t.bigint "user_id", null: false
    t.integer "volume_ml", null: false
    t.integer "remaining_ml", null: false
    t.string "storage_type", null: false
    t.string "status", default: "available", null: false
    t.string "source_type", default: "pumped", null: false
    t.string "label"
    t.datetime "stored_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "thawed_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["baby_id", "status"], name: "index_milk_stashes_on_baby_id_and_status"
    t.index ["baby_id", "storage_type"], name: "index_milk_stashes_on_baby_id_and_storage_type"
    t.index ["baby_id"], name: "index_milk_stashes_on_baby_id"
    t.index ["expires_at"], name: "index_milk_stashes_on_expires_at"
    t.index ["user_id"], name: "index_milk_stashes_on_user_id"
  end

  create_table "sleep_logs", force: :cascade do |t|
    t.bigint "baby_id", null: false
    t.bigint "user_id", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "duration_minutes"
    t.string "sleep_type", default: "nap", null: false
    t.string "location"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["baby_id", "started_at"], name: "index_sleep_logs_on_baby_id_and_started_at"
    t.index ["baby_id"], name: "index_sleep_logs_on_baby_id"
    t.index ["user_id"], name: "index_sleep_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", default: "", null: false
    t.string "role", default: "parent", null: false
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone_number"
    t.boolean "sms_enabled", default: false, null: false
    t.string "telegram_chat_id"
    t.string "telegram_link_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true, where: "(phone_number IS NOT NULL)"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["telegram_chat_id"], name: "index_users_on_telegram_chat_id", unique: true, where: "(telegram_chat_id IS NOT NULL)"
  end

  create_table "vaccinations", force: :cascade do |t|
    t.bigint "baby_id", null: false
    t.string "vaccine_name", null: false
    t.text "description"
    t.integer "recommended_age_days"
    t.date "administered_at"
    t.string "administered_by"
    t.string "lot_number"
    t.string "site"
    t.text "reactions"
    t.boolean "reminder_sent", default: false, null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["baby_id", "status"], name: "index_vaccinations_on_baby_id_and_status"
    t.index ["baby_id"], name: "index_vaccinations_on_baby_id"
  end

  create_table "weight_logs", force: :cascade do |t|
    t.bigint "baby_id", null: false
    t.bigint "user_id", null: false
    t.date "recorded_at", null: false
    t.integer "weight_grams", null: false
    t.decimal "height_cm", precision: 5, scale: 2
    t.decimal "head_circumference_cm", precision: 5, scale: 2
    t.string "measured_by"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["baby_id", "recorded_at"], name: "index_weight_logs_on_baby_id_and_recorded_at"
    t.index ["baby_id"], name: "index_weight_logs_on_baby_id"
    t.index ["user_id"], name: "index_weight_logs_on_user_id"
  end

  add_foreign_key "appointments", "babies"
  add_foreign_key "appointments", "users"
  add_foreign_key "babies", "users"
  add_foreign_key "diaper_changes", "babies"
  add_foreign_key "diaper_changes", "users"
  add_foreign_key "feedings", "babies"
  add_foreign_key "feedings", "users"
  add_foreign_key "milestones", "babies"
  add_foreign_key "milestones", "users"
  add_foreign_key "milk_stash_logs", "feedings"
  add_foreign_key "milk_stash_logs", "milk_stashes"
  add_foreign_key "milk_stash_logs", "users"
  add_foreign_key "milk_stashes", "babies"
  add_foreign_key "milk_stashes", "users"
  add_foreign_key "sleep_logs", "babies"
  add_foreign_key "sleep_logs", "users"
  add_foreign_key "vaccinations", "babies"
  add_foreign_key "weight_logs", "babies"
  add_foreign_key "weight_logs", "users"
end
