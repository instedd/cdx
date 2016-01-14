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

ActiveRecord::Schema.define(version: 20160105165742) do

  create_table "computed_policies", force: :cascade do |t|
    t.integer "user_id",                  limit: 4
    t.string  "action",                   limit: 255
    t.string  "resource_type",            limit: 255
    t.string  "resource_id",              limit: 255
    t.integer "condition_institution_id", limit: 4
    t.string  "condition_site_id",        limit: 255
    t.boolean "delegable",                            default: false
    t.integer "condition_device_id",      limit: 4
  end

  create_table "computed_policy_exceptions", force: :cascade do |t|
    t.integer "computed_policy_id",       limit: 4
    t.string  "action",                   limit: 255
    t.string  "resource_type",            limit: 255
    t.string  "resource_id",              limit: 255
    t.integer "condition_institution_id", limit: 4
    t.string  "condition_site_id",        limit: 255
    t.integer "condition_device_id",      limit: 4
  end

  create_table "conditions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conditions_manifests", id: false, force: :cascade do |t|
    t.integer "manifest_id",  limit: 4
    t.integer "condition_id", limit: 4
  end

  create_table "device_commands", force: :cascade do |t|
    t.integer  "device_id",  limit: 4
    t.string   "name",       limit: 255
    t.string   "command",    limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "device_logs", force: :cascade do |t|
    t.integer  "device_id",  limit: 4
    t.binary   "message",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "device_messages", force: :cascade do |t|
    t.binary   "raw_data",             limit: 65535
    t.integer  "device_id",            limit: 4
    t.boolean  "index_failed"
    t.text     "index_failure_reason", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "index_failure_data",   limit: 65535
  end

  add_index "device_messages", ["device_id"], name: "index_device_messages_on_device_id", using: :btree

  create_table "device_messages_test_results", force: :cascade do |t|
    t.integer "device_message_id", limit: 4
    t.integer "test_result_id",    limit: 4
  end

  add_index "device_messages_test_results", ["device_message_id"], name: "index_device_messages_test_results_on_device_message_id", using: :btree
  add_index "device_messages_test_results", ["test_result_id"], name: "index_device_messages_test_results_on_test_result_id", using: :btree

  create_table "device_models", force: :cascade do |t|
    t.string   "name",                            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "institution_id",                  limit: 4
    t.boolean  "supports_activation"
    t.datetime "published_at"
    t.string   "support_url",                     limit: 255
    t.string   "picture_file_name",               limit: 255
    t.string   "picture_content_type",            limit: 255
    t.integer  "picture_file_size",               limit: 4
    t.datetime "picture_updated_at"
    t.string   "setup_instructions_file_name",    limit: 255
    t.string   "setup_instructions_content_type", limit: 255
    t.integer  "setup_instructions_file_size",    limit: 4
    t.datetime "setup_instructions_updated_at"
  end

  add_index "device_models", ["published_at"], name: "index_device_models_on_published_at", using: :btree

  create_table "devices", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid",             limit: 255
    t.integer  "institution_id",   limit: 4
    t.integer  "device_model_id",  limit: 4
    t.string   "secret_key_hash",  limit: 255
    t.string   "time_zone",        limit: 255
    t.text     "custom_mappings",  limit: 65535
    t.integer  "site_id",          limit: 4
    t.string   "serial_number",    limit: 255
    t.string   "site_prefix",      limit: 255
    t.string   "activation_token", limit: 255
  end

  create_table "encounters", force: :cascade do |t|
    t.integer  "institution_id",  limit: 4
    t.integer  "patient_id",      limit: 4
    t.string   "uuid",            limit: 255
    t.string   "entity_id",       limit: 255
    t.binary   "sensitive_data",  limit: 65535
    t.text     "custom_fields",   limit: 65535
    t.text     "core_fields",     limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_phantom",                    default: true
    t.datetime "deleted_at"
    t.integer  "site_id",         limit: 4
    t.datetime "user_updated_at"
  end

  add_index "encounters", ["deleted_at"], name: "index_encounters_on_deleted_at", using: :btree
  add_index "encounters", ["site_id"], name: "index_encounters_on_site_id", using: :btree

  create_table "filters", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 255
    t.text     "query",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "filters", ["user_id"], name: "index_filters_on_user_id", using: :btree

  create_table "identities", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "provider",   limit: 255
    t.string   "token",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "institutions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid",       limit: 255
    t.string   "kind",       limit: 255, default: "institution"
  end

  add_index "institutions", ["user_id"], name: "index_institutions_on_user_id", using: :btree

  create_table "manifests", force: :cascade do |t|
    t.string   "version",         limit: 255
    t.text     "definition",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_version",     limit: 255
    t.integer  "device_model_id", limit: 4
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4,     null: false
    t.integer  "application_id",    limit: 4,     null: false
    t.string   "token",             limit: 255,   null: false
    t.integer  "expires_in",        limit: 4,     null: false
    t.text     "redirect_uri",      limit: 65535, null: false
    t.datetime "created_at",                      null: false
    t.datetime "revoked_at"
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4
    t.integer  "application_id",    limit: 4
    t.string   "token",             limit: 255, null: false
    t.string   "refresh_token",     limit: 255
    t.integer  "expires_in",        limit: 4
    t.datetime "revoked_at"
    t.datetime "created_at",                    null: false
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",         limit: 255,                null: false
    t.string   "uid",          limit: 255,                null: false
    t.string   "secret",       limit: 255,                null: false
    t.text     "redirect_uri", limit: 65535,              null: false
    t.string   "scopes",       limit: 255,   default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id",     limit: 4
    t.string   "owner_type",   limit: 255
  end

  add_index "oauth_applications", ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type", using: :btree
  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "old_passwords", force: :cascade do |t|
    t.string   "encrypted_password",       limit: 255, null: false
    t.string   "password_archivable_type", limit: 255, null: false
    t.integer  "password_archivable_id",   limit: 4,   null: false
    t.datetime "created_at"
  end

  add_index "old_passwords", ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable", using: :btree

  create_table "patients", force: :cascade do |t|
    t.binary   "sensitive_data", limit: 65535
    t.text     "custom_fields",  limit: 65535
    t.text     "core_fields",    limit: 65535
    t.string   "entity_id_hash", limit: 255
    t.string   "uuid",           limit: 255
    t.integer  "institution_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_phantom",                   default: true
    t.datetime "deleted_at"
    t.string   "location_geoid", limit: 60
    t.float    "lat",            limit: 24
    t.float    "lng",            limit: 24
    t.string   "address",        limit: 255
  end

  add_index "patients", ["deleted_at"], name: "index_patients_on_deleted_at", using: :btree
  add_index "patients", ["institution_id"], name: "index_patients_on_institution_id", using: :btree

  create_table "policies", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "granter_id", limit: 4
    t.text     "definition", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",           limit: 255, null: false
    t.integer  "institution_id", limit: 4,   null: false
    t.integer  "site_id",        limit: 4
    t.integer  "policy_id",      limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key",            limit: 255
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "role_id", limit: 4
    t.integer "user_id", limit: 4
  end

  create_table "sample_identifiers", force: :cascade do |t|
    t.integer  "sample_id",  limit: 4
    t.string   "entity_id",  limit: 255
    t.string   "uuid",       limit: 255
    t.integer  "site_id",    limit: 4
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sample_identifiers", ["deleted_at"], name: "index_sample_identifiers_on_deleted_at", using: :btree
  add_index "sample_identifiers", ["entity_id"], name: "index_sample_identifiers_on_entity_id", using: :btree
  add_index "sample_identifiers", ["sample_id"], name: "index_sample_identifiers_on_sample_id", using: :btree
  add_index "sample_identifiers", ["uuid"], name: "index_sample_identifiers_on_uuid", unique: true, using: :btree

  create_table "samples", force: :cascade do |t|
    t.binary   "sensitive_data", limit: 65535
    t.integer  "institution_id", limit: 4
    t.text     "custom_fields",  limit: 65535
    t.text     "core_fields",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "patient_id",     limit: 4
    t.integer  "encounter_id",   limit: 4
    t.boolean  "is_phantom",                   default: true
    t.datetime "deleted_at"
  end

  add_index "samples", ["deleted_at"], name: "index_samples_on_deleted_at", using: :btree
  add_index "samples", ["institution_id"], name: "index_samples_on_institution_id_and_entity_id", using: :btree
  add_index "samples", ["patient_id"], name: "index_samples_on_patient_id", using: :btree

  create_table "sites", force: :cascade do |t|
    t.string   "name",                             limit: 255
    t.integer  "institution_id",                   limit: 4
    t.string   "address",                          limit: 255
    t.string   "city",                             limit: 255
    t.string   "state",                            limit: 255
    t.string   "zip_code",                         limit: 255
    t.string   "country",                          limit: 255
    t.string   "region",                           limit: 255
    t.float    "lat",                              limit: 24
    t.float    "lng",                              limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location_geoid",                   limit: 60
    t.string   "uuid",                             limit: 255
    t.integer  "parent_id",                        limit: 4
    t.string   "prefix",                           limit: 255
    t.string   "sample_id_reset_policy",           limit: 255, default: "yearly"
    t.datetime "deleted_at"
    t.string   "main_phone_number",                limit: 255
    t.string   "email_address",                    limit: 255
    t.string   "last_sample_identifier_entity_id", limit: 255
    t.date     "last_sample_identifier_date"
  end

  add_index "sites", ["deleted_at"], name: "index_sites_on_deleted_at", using: :btree

  create_table "ssh_keys", force: :cascade do |t|
    t.text     "public_key", limit: 65535
    t.integer  "device_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ssh_keys", ["device_id"], name: "index_ssh_keys_on_device_id", using: :btree

  create_table "subscribers", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.string   "name",         limit: 255
    t.string   "url",          limit: 255
    t.text     "fields",       limit: 65535
    t.datetime "last_run_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url_user",     limit: 255
    t.string   "url_password", limit: 255
    t.integer  "filter_id",    limit: 4
    t.string   "verb",         limit: 255,   default: "GET"
  end

  add_index "subscribers", ["filter_id"], name: "index_subscribers_on_filter_id", using: :btree

  create_table "test_result_parsed_data", force: :cascade do |t|
    t.integer  "test_result_id", limit: 4
    t.binary   "data",           limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "test_results", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid",                 limit: 255
    t.text     "custom_fields",        limit: 65535
    t.string   "test_id",              limit: 255
    t.binary   "sensitive_data",       limit: 65535
    t.integer  "device_id",            limit: 4
    t.integer  "patient_id",           limit: 4
    t.text     "core_fields",          limit: 65535
    t.integer  "encounter_id",         limit: 4
    t.integer  "site_id",              limit: 4
    t.integer  "institution_id",       limit: 4
    t.integer  "sample_identifier_id", limit: 4
    t.string   "site_prefix",          limit: 255
    t.datetime "deleted_at"
  end

  add_index "test_results", ["deleted_at"], name: "index_test_results_on_deleted_at", using: :btree
  add_index "test_results", ["device_id"], name: "index_test_results_on_device_id", using: :btree
  add_index "test_results", ["institution_id"], name: "index_test_results_on_institution_id", using: :btree
  add_index "test_results", ["patient_id"], name: "index_test_results_on_patient_id", using: :btree
  add_index "test_results", ["sample_identifier_id"], name: "index_test_results_on_sample_identifier_id", using: :btree
  add_index "test_results", ["site_id"], name: "index_test_results_on_site_id", using: :btree
  add_index "test_results", ["uuid"], name: "index_test_results_on_uuid", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                          limit: 255, default: "",    null: false
    t.string   "encrypted_password",             limit: 255, default: "",    null: false
    t.string   "reset_password_token",           limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                  limit: 4,   default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",             limit: 255
    t.string   "last_sign_in_ip",                limit: 255
    t.string   "confirmation_token",             limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",              limit: 255
    t.integer  "failed_attempts",                limit: 4,   default: 0,     null: false
    t.string   "unlock_token",                   limit: 255
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "password_changed_at"
    t.string   "locale",                         limit: 255, default: "en"
    t.boolean  "timestamps_in_device_time_zone",             default: false
    t.string   "time_zone",                      limit: 255, default: "UTC"
    t.string   "first_name",                     limit: 255
    t.string   "last_name",                      limit: 255
    t.string   "invitation_token",               limit: 255
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit",               limit: 4
    t.integer  "invited_by_id",                  limit: 4
    t.string   "invited_by_type",                limit: 255
    t.integer  "invitations_count",              limit: 4,   default: 0
    t.string   "last_navigation_context",        limit: 255
    t.boolean  "is_active",                                  default: true
    t.string   "telephone",                      limit: 255
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["last_name"], name: "index_users_on_last_name", using: :btree
  add_index "users", ["password_changed_at"], name: "index_users_on_password_changed_at", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  add_foreign_key "encounters", "sites"
end
