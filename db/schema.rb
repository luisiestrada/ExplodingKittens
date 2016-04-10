# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160410014258) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "games", force: :cascade do |t|
    t.boolean  "active",     default: false, null: false
    t.integer  "winner_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "games", ["winner_id"], name: "index_games_on_winner_id", using: :btree

  create_table "stats", force: :cascade do |t|
    t.integer "user_id",                        null: false
    t.integer "game_id"
    t.string  "type",                           null: false
    t.integer "cards_played",       default: 0, null: false
    t.integer "card_combos_played", default: 0, null: false
    t.integer "players_killed",     default: 0, null: false
  end

  add_index "stats", ["game_id"], name: "index_stats_on_game_id", using: :btree
  add_index "stats", ["type"], name: "index_stats_on_type", using: :btree
  add_index "stats", ["user_id"], name: "index_stats_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  null: false
    t.string   "username"
    t.string   "password",               null: false
    t.string   "avatar_url"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "wins",       default: 0, null: false
    t.integer  "losses",     default: 0, null: false
    t.integer  "game_id"
  end

end
