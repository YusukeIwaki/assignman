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

ActiveRecord::Schema[8.0].define(version: 2025_07_26_002813) do
  create_table "admins", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["organization_id"], name: "index_admins_on_organization_id"
    t.index ["user_id"], name: "index_admins_on_user_id"
  end

  create_table "detailed_project_assignments", force: :cascade do |t|
    t.integer "member_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.decimal "allocation_percentage", precision: 5, scale: 1, default: "100.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "standard_project_id"
    t.index ["member_id"], name: "index_detailed_project_assignments_on_member_id"
    t.index ["standard_project_id"], name: "index_detailed_project_assignments_on_standard_project_id"
  end

  create_table "member_skills", force: :cascade do |t|
    t.integer "member_id", null: false
    t.integer "skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id", "skill_id"], name: "index_member_skills_on_member_id_and_skill_id", unique: true
    t.index ["member_id"], name: "index_member_skills_on_member_id"
    t.index ["skill_id"], name: "index_member_skills_on_skill_id"
  end

  create_table "members", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.decimal "capacity", precision: 5, scale: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_members_on_organization_id"
  end

  create_table "ongoing_assignments", force: :cascade do |t|
    t.integer "member_id", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.decimal "allocation_percentage", precision: 5, scale: 1, default: "100.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ongoing_project_id"
    t.index ["member_id"], name: "index_ongoing_assignments_on_member_id"
    t.index ["ongoing_project_id"], name: "index_ongoing_assignments_on_ongoing_project_id"
  end

  create_table "ongoing_projects", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.string "client_name"
    t.decimal "budget", precision: 15, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_ongoing_projects_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "rough_project_assignments", force: :cascade do |t|
    t.integer "member_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.decimal "allocation_percentage", precision: 5, scale: 1, default: "100.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "standard_project_id"
    t.index ["member_id"], name: "index_rough_project_assignments_on_member_id"
    t.index ["standard_project_id"], name: "index_rough_project_assignments_on_standard_project_id"
  end

  create_table "skills", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_skills_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_skills_on_organization_id"
  end

  create_table "standard_projects", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.string "status", default: "tentative", null: false
    t.string "client_name"
    t.decimal "budget", precision: 15, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_standard_projects_on_organization_id"
  end

  create_table "user_credentials", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "email", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_user_credentials_on_email", unique: true
    t.index ["user_id"], name: "index_user_credentials_on_user_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.text "bio"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "admins", "organizations"
  add_foreign_key "admins", "users"
  add_foreign_key "detailed_project_assignments", "members"
  add_foreign_key "detailed_project_assignments", "standard_projects"
  add_foreign_key "member_skills", "members"
  add_foreign_key "member_skills", "skills"
  add_foreign_key "members", "organizations"
  add_foreign_key "ongoing_assignments", "members"
  add_foreign_key "ongoing_assignments", "ongoing_projects"
  add_foreign_key "ongoing_projects", "organizations"
  add_foreign_key "rough_project_assignments", "members"
  add_foreign_key "rough_project_assignments", "standard_projects"
  add_foreign_key "skills", "organizations"
  add_foreign_key "standard_projects", "organizations"
  add_foreign_key "user_credentials", "users"
  add_foreign_key "user_profiles", "users"
end
