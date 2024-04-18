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

ActiveRecord::Schema[7.0].define(version: 2024_04_18_104344) do
  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.string "article_type"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "author"
    t.integer "votes_up", default: 0
    t.integer "votes_down", default: 0
    t.boolean "boosted", default: false
    t.integer "magazine_id", null: false
    t.integer "user_id", null: false
    t.integer "num_boost", default: 0
    t.index ["magazine_id"], name: "index_articles_on_magazine_id"
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "boosts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_boosts_on_article_id"
    t.index ["user_id"], name: "index_boosts_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.integer "article_id"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "votes_up"
    t.integer "votes_down"
  end

  create_table "magazines", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "full_name"
    t.string "uid"
    t.string "avatar_url"
    t.string "provider"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vote_articles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "article_id", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_vote_articles_on_article_id"
    t.index ["user_id"], name: "index_vote_articles_on_user_id"
  end

  add_foreign_key "articles", "magazines"
  add_foreign_key "articles", "users"
  add_foreign_key "boosts", "articles"
  add_foreign_key "boosts", "users"
  add_foreign_key "vote_articles", "articles"
  add_foreign_key "vote_articles", "users"
end
