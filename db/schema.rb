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

ActiveRecord::Schema[8.1].define(version: 2026_10_23_110000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "draft_picks", force: :cascade do |t|
    t.bigint "draft_id", null: false
    t.bigint "hero_id", null: false
    t.string "team", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draft_id", "hero_id"], name: "index_draft_picks_on_draft_id_and_hero_id", unique: true
    t.index ["draft_id", "team", "position"], name: "index_draft_picks_on_draft_id_and_team_and_position", unique: true
    t.index ["draft_id"], name: "index_draft_picks_on_draft_id"
    t.index ["hero_id"], name: "index_draft_picks_on_hero_id"
    t.check_constraint "\"position\" >= 1 AND \"position\" <= 5", name: "draft_picks_position_range"
    t.check_constraint "team::text = ANY (ARRAY['ally'::character varying, 'enemy'::character varying]::text[])", name: "draft_picks_team_valid"
  end

  create_table "drafts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_drafts_on_user_id"
    t.check_constraint "length(TRIM(BOTH FROM title)) >= 1 AND length(TRIM(BOTH FROM title)) <= 100", name: "drafts_title_length"
  end

  create_table "heroes", force: :cascade do |t|
    t.string "name", null: false
    t.string "role", null: false
    t.integer "support", default: 0, null: false
    t.integer "control", default: 0, null: false
    t.integer "damage", default: 0, null: false
    t.integer "durability", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_heroes_on_lower_name", unique: true
    t.check_constraint "control >= 0 AND control <= 3", name: "heroes_control_range"
    t.check_constraint "damage >= 0 AND damage <= 3", name: "heroes_damage_range"
    t.check_constraint "durability >= 0 AND durability <= 3", name: "heroes_durability_range"
    t.check_constraint "length(TRIM(BOTH FROM name)) > 0", name: "heroes_name_present"
    t.check_constraint "length(TRIM(BOTH FROM role)) > 0", name: "heroes_role_present"
    t.check_constraint "support >= 0 AND support <= 3", name: "heroes_support_range"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "draft_picks", "drafts"
  add_foreign_key "draft_picks", "heroes"
  add_foreign_key "drafts", "users"
end
