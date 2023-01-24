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

ActiveRecord::Schema.define(version: 20230123114004) do

  create_table "alert_condition_results", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string  "result"
    t.integer "alert_id"
  end

  create_table "alert_histories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.boolean  "read",                        default: false
    t.integer  "user_id"
    t.integer  "alert_id"
    t.integer  "test_result_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "for_aggregation_calculation", default: false
    t.datetime "test_result_updated_at"
    t.index ["alert_id"], name: "index_alert_histories_on_alert_id", using: :btree
    t.index ["user_id"], name: "index_alert_histories_on_user_id", using: :btree
  end

  create_table "alert_recipients", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "user_id"
    t.integer  "alert_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.integer  "role_id"
    t.integer  "recipient_type", default: 0
    t.string   "telephone"
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "deleted_at"
    t.index ["alert_id"], name: "index_alert_recipients_on_alert_id", using: :btree
    t.index ["deleted_at"], name: "index_alert_recipients_on_deleted_at", using: :btree
    t.index ["user_id"], name: "index_alert_recipients_on_user_id", using: :btree
  end

  create_table "alerts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "description"
    t.boolean  "enabled",                                              default: true
    t.datetime "last_alert"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "error_code"
    t.integer  "category_type"
    t.integer  "aggregation_type",                                     default: 0
    t.text     "query",                               limit: 16777215
    t.text     "message",                             limit: 16777215
    t.integer  "channel_type",                                         default: 0
    t.integer  "aggregation_frequency",                                default: 0
    t.integer  "sms_limit",                                            default: 0
    t.integer  "anomalie_type",                                        default: 0
    t.boolean  "notify_patients",                                      default: false
    t.text     "sms_message",                         limit: 16777215
    t.datetime "deleted_at"
    t.integer  "test_result_min_threshold"
    t.integer  "test_result_max_threshold"
    t.integer  "aggregation_threshold",                                default: 0
    t.string   "sample_id"
    t.integer  "utilization_efficiency_type",                          default: 0
    t.integer  "utilization_efficiency_number",                        default: 0
    t.datetime "utilization_efficiency_last_checked"
    t.integer  "email_limit",                                          default: 0
    t.boolean  "use_aggregation_percentage",                           default: false
    t.integer  "institution_id"
    t.datetime "time_last_aggregation_checked"
    t.index ["deleted_at"], name: "index_alerts_on_deleted_at", using: :btree
    t.index ["institution_id"], name: "index_alerts_on_institution_id", using: :btree
    t.index ["user_id"], name: "index_alerts_on_user_id", using: :btree
  end

  create_table "alerts_conditions", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer "alert_id",     null: false
    t.integer "condition_id", null: false
    t.index ["alert_id", "condition_id"], name: "index_alerts_conditions_on_alert_id_and_condition_id", using: :btree
    t.index ["condition_id", "alert_id"], name: "index_alerts_conditions_on_condition_id_and_alert_id", using: :btree
  end

  create_table "alerts_devices", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer "alert_id",  null: false
    t.integer "device_id", null: false
    t.index ["alert_id", "device_id"], name: "index_alerts_devices_on_alert_id_and_device_id", using: :btree
    t.index ["device_id", "alert_id"], name: "index_alerts_devices_on_device_id_and_alert_id", using: :btree
  end

  create_table "alerts_sites", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer "alert_id", null: false
    t.integer "site_id",  null: false
  end

  create_table "assay_attachments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "sample_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "result"
    t.integer  "loinc_code_id"
    t.integer  "assay_file_id"
    t.integer  "qc_info_id"
    t.index ["assay_file_id"], name: "index_assay_attachments_on_assay_file_id", using: :btree
    t.index ["loinc_code_id"], name: "index_assay_attachments_on_loinc_code_id", using: :btree
    t.index ["qc_info_id"], name: "index_assay_attachments_on_qc_info_id", using: :btree
    t.index ["result"], name: "index_assay_attachments_on_result", using: :btree
    t.index ["sample_id"], name: "index_assay_attachments_on_sample_id", using: :btree
  end

  create_table "assay_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "assay_attachment_id"
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["assay_attachment_id"], name: "index_assay_files_on_assay_attachment_id", using: :btree
  end

  create_table "batches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "uuid"
    t.text     "core_fields",    limit: 16777215
    t.text     "custom_fields",  limit: 16777215
    t.binary   "sensitive_data", limit: 65535
    t.datetime "deleted_at"
    t.integer  "institution_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "isolate_name"
    t.string   "batch_number"
    t.integer  "site_id"
    t.string   "site_prefix"
    t.datetime "date_produced"
    t.index ["date_produced"], name: "index_batches_on_date_produced", using: :btree
    t.index ["deleted_at"], name: "index_batches_on_deleted_at", using: :btree
    t.index ["institution_id"], name: "index_batches_on_institution_id", using: :btree
    t.index ["site_id"], name: "index_batches_on_site_id", using: :btree
  end

  create_table "box_report_samples", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer "sample_id",     null: false
    t.integer "box_report_id", null: false
    t.index ["box_report_id"], name: "index_box_report_samples_on_box_report_id", using: :btree
    t.index ["sample_id"], name: "index_box_report_samples_on_sample_id", using: :btree
  end

  create_table "box_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "institution_id",               null: false
    t.integer  "site_id"
    t.string   "site_prefix"
    t.text     "core_fields",    limit: 65535
    t.text     "custom_fields",  limit: 65535
    t.binary   "sensitive_data", limit: 65535
    t.string   "name"
    t.float    "threshold",      limit: 24
    t.datetime "deleted_at"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["created_at"], name: "index_box_reports_on_created_at", using: :btree
    t.index ["deleted_at"], name: "index_box_reports_on_deleted_at", using: :btree
    t.index ["institution_id"], name: "index_box_reports_on_institution_id", using: :btree
    t.index ["site_id"], name: "index_box_reports_on_site_id", using: :btree
    t.index ["site_prefix"], name: "index_box_reports_on_site_prefix", using: :btree
  end

  create_table "box_transfers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "box_id",              null: false
    t.integer  "transfer_package_id", null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["box_id"], name: "index_box_transfers_on_box_id", using: :btree
    t.index ["transfer_package_id"], name: "index_box_transfers_on_transfer_package_id", using: :btree
  end

  create_table "boxes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "uuid",           limit: 36,                    null: false
    t.integer  "institution_id"
    t.integer  "site_id"
    t.string   "site_prefix"
    t.text     "core_fields",    limit: 65535
    t.text     "custom_fields",  limit: 65535
    t.binary   "sensitive_data", limit: 65535
    t.string   "purpose"
    t.datetime "deleted_at"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.boolean  "blinded",                      default: false, null: false
    t.index ["created_at"], name: "index_boxes_on_created_at", using: :btree
    t.index ["deleted_at"], name: "index_boxes_on_deleted_at", using: :btree
    t.index ["institution_id"], name: "index_boxes_on_institution_id", using: :btree
    t.index ["purpose"], name: "index_boxes_on_purpose", using: :btree
    t.index ["site_id"], name: "index_boxes_on_site_id", using: :btree
    t.index ["site_prefix"], name: "index_boxes_on_site_prefix", using: :btree
    t.index ["uuid"], name: "index_boxes_on_uuid", using: :btree
  end

  create_table "computed_policies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer "user_id"
    t.string  "action"
    t.string  "resource_type"
    t.string  "resource_id"
    t.integer "condition_institution_id"
    t.string  "condition_site_id"
    t.boolean "delegable",                default: false
    t.integer "condition_device_id"
    t.boolean "include_subsites",         default: false
  end

  create_table "computed_policy_exceptions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer "computed_policy_id"
    t.string  "action"
    t.string  "resource_type"
    t.string  "resource_id"
    t.integer "condition_institution_id"
    t.string  "condition_site_id"
    t.integer "condition_device_id"
  end

  create_table "conditions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conditions_manifests", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer "manifest_id"
    t.integer "condition_id"
  end

  create_table "device_commands", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "device_id"
    t.string   "name"
    t.string   "command"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "device_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "device_id"
    t.binary   "message",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "device_messages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.binary   "raw_data",             limit: 65535
    t.integer  "device_id"
    t.boolean  "index_failed"
    t.text     "index_failure_reason", limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "index_failure_data",   limit: 16777215
    t.integer  "site_id"
    t.index ["device_id"], name: "index_device_messages_on_device_id", using: :btree
    t.index ["site_id"], name: "index_device_messages_on_site_id", using: :btree
  end

  create_table "device_messages_test_results", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer "device_message_id"
    t.integer "test_result_id"
    t.index ["device_message_id"], name: "index_device_messages_test_results_on_device_message_id", using: :btree
    t.index ["test_result_id"], name: "index_device_messages_test_results_on_test_result_id", using: :btree
  end

  create_table "device_models", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "institution_id"
    t.datetime "published_at"
    t.boolean  "supports_activation"
    t.string   "support_url"
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.string   "setup_instructions_file_name"
    t.string   "setup_instructions_content_type"
    t.integer  "setup_instructions_file_size"
    t.datetime "setup_instructions_updated_at"
    t.boolean  "supports_ftp"
    t.string   "filename_pattern"
    t.index ["published_at"], name: "index_device_models_on_published_at", using: :btree
  end

  create_table "devices", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.integer  "institution_id"
    t.integer  "device_model_id"
    t.string   "secret_key_hash"
    t.string   "time_zone"
    t.text     "custom_mappings",  limit: 16777215
    t.integer  "site_id"
    t.string   "serial_number"
    t.string   "site_prefix"
    t.string   "activation_token"
    t.string   "ftp_hostname"
    t.string   "ftp_username"
    t.string   "ftp_password"
    t.string   "ftp_directory"
    t.integer  "ftp_port"
    t.datetime "deleted_at"
    t.boolean  "ftp_passive"
    t.index ["deleted_at"], name: "index_devices_on_deleted_at", using: :btree
  end

  create_table "encounters", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "institution_id"
    t.integer  "patient_id"
    t.string   "uuid"
    t.string   "entity_id"
    t.binary   "sensitive_data",  limit: 65535
    t.text     "custom_fields",   limit: 16777215
    t.text     "core_fields",     limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_phantom",                       default: true
    t.datetime "deleted_at"
    t.integer  "site_id"
    t.datetime "user_updated_at"
    t.string   "site_prefix"
    t.datetime "start_time"
    t.index ["deleted_at"], name: "index_encounters_on_deleted_at", using: :btree
    t.index ["site_id"], name: "index_encounters_on_site_id", using: :btree
  end

  create_table "file_messages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string  "filename"
    t.string  "status"
    t.text    "message",           limit: 16777215
    t.integer "device_id"
    t.integer "device_message_id"
    t.string  "ftp_hostname"
    t.string  "ftp_username"
    t.string  "ftp_password"
    t.string  "ftp_directory"
    t.integer "ftp_port"
    t.boolean "ftp_passive"
    t.index ["device_id"], name: "index_file_messages_on_device_id", using: :btree
    t.index ["ftp_hostname", "ftp_port", "ftp_directory", "status"], name: "index_file_messages_on_ftp_and_status", using: :btree
  end

  create_table "filters", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "query",      limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_filters_on_user_id", using: :btree
  end

  create_table "identities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "institutions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.string   "kind",                          default: "institution"
    t.integer  "pending_institution_invite_id"
    t.index ["user_id"], name: "index_institutions_on_user_id", using: :btree
  end

  create_table "loinc_codes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string "loinc_number"
    t.string "component"
    t.index ["component"], name: "index_loinc_codes_on_component", using: :btree
    t.index ["loinc_number"], name: "index_loinc_codes_on_loinc_number", using: :btree
  end

  create_table "manifests", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "version"
    t.text     "definition",      limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_version"
    t.integer  "device_model_id"
  end

  create_table "notes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.text     "description", limit: 16777215
    t.integer  "user_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "sample_id"
    t.integer  "qc_info_id"
    t.index ["qc_info_id"], name: "index_notes_on_qc_info_id", using: :btree
    t.index ["sample_id"], name: "index_notes_on_sample_id", using: :btree
    t.index ["user_id"], name: "index_notes_on_user_id", using: :btree
  end

  create_table "oauth_access_grants", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "resource_owner_id",                  null: false
    t.integer  "application_id",                     null: false
    t.string   "token",                              null: false
    t.integer  "expires_in",                         null: false
    t.text     "redirect_uri",      limit: 16777215, null: false
    t.datetime "created_at",                         null: false
    t.datetime "revoked_at"
    t.string   "scopes"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree
  end

  create_table "oauth_access_tokens", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",             null: false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree
  end

  create_table "oauth_applications", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "name",                                       null: false
    t.string   "uid",                                        null: false
    t.string   "secret",                                     null: false
    t.text     "redirect_uri", limit: 16777215,              null: false
    t.string   "scopes",                        default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type", using: :btree
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree
  end

  create_table "old_passwords", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "encrypted_password",       null: false
    t.string   "password_archivable_type", null: false
    t.integer  "password_archivable_id",   null: false
    t.datetime "created_at"
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable", using: :btree
  end

  create_table "patients", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.binary   "sensitive_data", limit: 65535
    t.text     "custom_fields",  limit: 16777215
    t.text     "core_fields",    limit: 16777215
    t.string   "entity_id_hash"
    t.string   "uuid"
    t.integer  "institution_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_phantom",                      default: true
    t.datetime "deleted_at"
    t.string   "location_geoid", limit: 60
    t.float    "lat",            limit: 24
    t.float    "lng",            limit: 24
    t.string   "address"
    t.string   "name"
    t.string   "entity_id"
    t.integer  "site_id"
    t.string   "site_prefix"
    t.index ["deleted_at"], name: "index_patients_on_deleted_at", using: :btree
    t.index ["institution_id"], name: "index_patients_on_institution_id", using: :btree
    t.index ["site_id"], name: "index_patients_on_site_id", using: :btree
  end

  create_table "pending_institution_invites", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "invited_user_email"
    t.integer  "invited_by_user_id"
    t.string   "institution_name"
    t.string   "institution_kind",   default: "institution"
    t.string   "status",             default: "pending"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.index ["invited_by_user_id"], name: "index_pending_institution_invites_on_invited_by_user_id", using: :btree
    t.index ["invited_user_email"], name: "index_pending_institution_invites_on_invited_user_email", using: :btree
  end

  create_table "policies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "user_id"
    t.integer  "granter_id"
    t.text     "definition", limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  create_table "qc_infos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "uuid"
    t.string   "batch_number"
    t.text     "core_fields",    limit: 16777215
    t.text     "custom_fields",  limit: 16777215
    t.binary   "sensitive_data", limit: 65535
    t.integer  "sample_qc_id"
    t.datetime "deleted_at"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["batch_number"], name: "index_qc_infos_on_batch_number", using: :btree
    t.index ["uuid"], name: "index_qc_infos_on_uuid", using: :btree
  end

  create_table "recipient_notification_histories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "user_id"
    t.integer  "alert_recipient_id"
    t.integer  "alert_history_id"
    t.integer  "alert_id"
    t.integer  "channel_type"
    t.string   "message_sent"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sms_response_id"
    t.string   "sms_response_guid"
    t.string   "sms_response_token"
    t.index ["user_id"], name: "index_recipient_notification_histories_on_user_id", using: :btree
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "name",           null: false
    t.integer  "institution_id", null: false
    t.integer  "site_id"
    t.integer  "policy_id",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
    t.string   "site_prefix"
  end

  create_table "roles_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "sample_identifiers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "sample_id"
    t.string   "entity_id"
    t.string   "uuid"
    t.integer  "site_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["deleted_at"], name: "index_sample_identifiers_on_deleted_at", using: :btree
    t.index ["entity_id"], name: "index_sample_identifiers_on_entity_id", using: :btree
    t.index ["sample_id"], name: "index_sample_identifiers_on_sample_id", using: :btree
    t.index ["uuid"], name: "index_sample_identifiers_on_uuid", unique: true, using: :btree
  end

  create_table "samples", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.binary   "sensitive_data",   limit: 65535
    t.integer  "institution_id"
    t.text     "custom_fields",    limit: 16777215
    t.text     "core_fields",      limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "patient_id"
    t.integer  "encounter_id"
    t.boolean  "is_phantom",                        default: true
    t.datetime "deleted_at"
    t.integer  "batch_id"
    t.string   "isolate_name"
    t.integer  "site_id"
    t.string   "site_prefix"
    t.string   "specimen_role"
    t.integer  "qc_info_id"
    t.string   "old_batch_number"
    t.integer  "box_id"
    t.boolean  "distractor"
    t.string   "instruction"
    t.index ["batch_id"], name: "index_samples_on_batch_id", using: :btree
    t.index ["box_id"], name: "index_samples_on_box_id", using: :btree
    t.index ["deleted_at"], name: "index_samples_on_deleted_at", using: :btree
    t.index ["institution_id"], name: "index_samples_on_institution_id_and_entity_id", using: :btree
    t.index ["isolate_name"], name: "index_samples_on_isolate_name", using: :btree
    t.index ["patient_id"], name: "index_samples_on_patient_id", using: :btree
    t.index ["qc_info_id"], name: "index_samples_on_qc_info_id", using: :btree
    t.index ["site_id"], name: "index_samples_on_site_id", using: :btree
    t.index ["specimen_role"], name: "index_samples_on_specimen_role", using: :btree
  end

  create_table "sites", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "name"
    t.integer  "institution_id"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip_code"
    t.string   "country"
    t.string   "region"
    t.float    "lat",                              limit: 24
    t.float    "lng",                              limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location_geoid",                   limit: 60
    t.string   "uuid"
    t.integer  "parent_id"
    t.string   "prefix"
    t.string   "sample_id_reset_policy",                      default: "yearly"
    t.datetime "deleted_at"
    t.string   "main_phone_number"
    t.string   "email_address"
    t.string   "last_sample_identifier_entity_id"
    t.date     "last_sample_identifier_date"
    t.boolean  "allows_manual_entry"
    t.index ["deleted_at"], name: "index_sites_on_deleted_at", using: :btree
  end

  create_table "ssh_keys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.text     "public_key", limit: 16777215
    t.integer  "device_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["device_id"], name: "index_ssh_keys_on_device_id", using: :btree
  end

  create_table "subscribers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "url"
    t.text     "fields",       limit: 16777215
    t.datetime "last_run_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url_user"
    t.string   "url_password"
    t.integer  "filter_id"
    t.string   "verb",                          default: "GET"
    t.index ["filter_id"], name: "index_subscribers_on_filter_id", using: :btree
  end

  create_table "test_result_parsed_data", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "test_result_id"
    t.binary   "data",           limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "test_results", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.text     "custom_fields",        limit: 16777215
    t.string   "test_id"
    t.binary   "sensitive_data",       limit: 65535
    t.integer  "device_id"
    t.integer  "patient_id"
    t.text     "core_fields",          limit: 16777215
    t.integer  "encounter_id"
    t.integer  "site_id"
    t.integer  "institution_id"
    t.integer  "sample_identifier_id"
    t.string   "site_prefix"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_test_results_on_deleted_at", using: :btree
    t.index ["device_id"], name: "index_test_results_on_device_id", using: :btree
    t.index ["institution_id"], name: "index_test_results_on_institution_id", using: :btree
    t.index ["patient_id"], name: "index_test_results_on_patient_id", using: :btree
    t.index ["sample_identifier_id"], name: "index_test_results_on_sample_identifier_id", using: :btree
    t.index ["site_id"], name: "index_test_results_on_site_id", using: :btree
    t.index ["uuid"], name: "index_test_results_on_uuid", using: :btree
  end

  create_table "transfer_packages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.integer  "receiver_institution_id",                            null: false
    t.string   "uuid",                    limit: 36,                 null: false
    t.string   "recipient"
    t.boolean  "includes_qc_info",                   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sender_institution_id",                              null: false
    t.datetime "confirmed_at"
    t.index ["confirmed_at"], name: "index_transfer_packages_on_confirmed_at", using: :btree
    t.index ["created_at"], name: "index_transfer_packages_on_created_at", using: :btree
    t.index ["receiver_institution_id"], name: "index_transfer_packages_on_receiver_institution_id", using: :btree
    t.index ["sender_institution_id"], name: "index_transfer_packages_on_sender_institution_id", using: :btree
    t.index ["uuid"], name: "index_transfer_packages_on_uuid", unique: true, using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci" do |t|
    t.string   "email",                          default: "",    null: false
    t.string   "encrypted_password",             default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                  default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",                default: 0,     null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "password_changed_at"
    t.string   "locale",                         default: "en"
    t.boolean  "timestamps_in_device_time_zone", default: false
    t.string   "time_zone",                      default: "UTC"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",              default: 0
    t.string   "last_navigation_context"
    t.boolean  "is_active",                      default: true
    t.string   "telephone"
    t.boolean  "sidebar_open",                   default: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
    t.index ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
    t.index ["last_name"], name: "index_users_on_last_name", using: :btree
    t.index ["password_changed_at"], name: "index_users_on_password_changed_at", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  end

  add_foreign_key "alerts", "institutions"
  add_foreign_key "assay_attachments", "assay_files"
  add_foreign_key "assay_attachments", "loinc_codes"
  add_foreign_key "assay_attachments", "samples"
  add_foreign_key "batches", "sites"
  add_foreign_key "box_transfers", "boxes"
  add_foreign_key "box_transfers", "transfer_packages"
  add_foreign_key "device_messages", "sites"
  add_foreign_key "encounters", "sites"
  add_foreign_key "notes", "samples"
  add_foreign_key "patients", "sites"
  add_foreign_key "samples", "batches"
  add_foreign_key "samples", "sites"
end
