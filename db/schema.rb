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

ActiveRecord::Schema.define(version: 20150305175247) do

  create_table "activation_tokens", force: true do |t|
    t.string   "value"
    t.string   "client_id"
    t.integer  "device_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activation_tokens", ["device_id"], name: "index_activation_tokens_on_device_id", using: :btree
  add_index "activation_tokens", ["value"], name: "index_activation_tokens_on_value", unique: true, using: :btree

  create_table "activations", force: true do |t|
    t.integer  "activation_token_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activations", ["activation_token_id"], name: "index_activations_on_activation_token_id", unique: true, using: :btree

  create_table "device_events", force: true do |t|
    t.binary   "raw_data"
    t.integer  "device_id"
    t.boolean  "index_failed"
    t.text     "index_failure_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "device_events", ["device_id"], name: "index_device_events_on_device_id", using: :btree

  create_table "device_events_events", force: true do |t|
    t.integer "device_event_id"
    t.integer "event_id"
  end

  add_index "device_events_events", ["device_event_id"], name: "index_device_events_events_on_device_event_id", using: :btree
  add_index "device_events_events", ["event_id"], name: "index_device_events_events_on_event_id", using: :btree

  create_table "device_models", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "device_models_manifests", id: false, force: true do |t|
    t.integer "manifest_id"
    t.integer "device_model_id"
  end

  create_table "devices", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.integer  "institution_id"
    t.integer  "device_model_id"
    t.string   "secret_key"
  end

  create_table "devices_laboratories", id: false, force: true do |t|
    t.integer "device_id"
    t.integer "laboratory_id"
  end

  create_table "events", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.text     "custom_fields"
    t.string   "event_id"
    t.integer  "sample_id"
    t.binary   "sensitive_data"
    t.integer  "device_id"
  end

  add_index "events", ["sample_id"], name: "index_events_on_sample_id", using: :btree
  add_index "events", ["uuid"], name: "index_events_on_uuid", using: :btree

  create_table "filters", force: true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "query"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "filters", ["user_id"], name: "index_filters_on_user_id", using: :btree

  create_table "identities", force: true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "institutions", force: true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "institutions", ["user_id"], name: "index_institutions_on_user_id", using: :btree

  create_table "laboratories", force: true do |t|
    t.string   "name"
    t.integer  "institution_id"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip_code"
    t.string   "country"
    t.string   "region"
    t.float    "lat"
    t.float    "lng"
    t.integer  "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "locations", force: true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.float    "lat"
    t.float    "lng"
    t.integer  "depth"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "admin_level"
    t.string   "geo_id"
  end

  add_index "locations", ["depth"], name: "index_locations_on_depth", using: :btree
  add_index "locations", ["lft"], name: "index_locations_on_lft", using: :btree
  add_index "locations", ["parent_id"], name: "index_locations_on_parent_id", using: :btree
  add_index "locations", ["rgt"], name: "index_locations_on_rgt", using: :btree

  create_table "manifests", force: true do |t|
    t.string   "version"
    t.text     "definition"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_version"
  end

  create_table "policies", force: true do |t|
    t.integer  "user_id"
    t.integer  "granter_id"
    t.text     "definition"
    t.boolean  "delegable"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  create_table "samples", force: true do |t|
    t.string  "uuid"
    t.binary  "sensitive_data"
    t.integer "institution_id"
    t.text    "custom_fields"
    t.string  "sample_uid_hash"
    t.text    "indexed_fields"
  end

  add_index "samples", ["institution_id", "sample_uid_hash"], name: "index_samples_on_institution_id_and_sample_uid_hash", using: :btree
  add_index "samples", ["uuid"], name: "index_samples_on_uuid", using: :btree

  create_table "ssh_keys", force: true do |t|
    t.text     "public_key"
    t.integer  "device_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ssh_keys", ["device_id"], name: "index_ssh_keys_on_device_id", using: :btree

  create_table "subscribers", force: true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "url"
    t.text     "fields"
    t.datetime "last_run_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url_user"
    t.string   "url_password"
    t.integer  "filter_id"
    t.string   "verb",         default: "GET"
  end

  add_index "subscribers", ["filter_id"], name: "index_subscribers_on_filter_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

end
