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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140220190534) do

  add_extension "hstore"

  create_table "audio_files", :force => true do |t|
    t.integer  "item_id"
    t.string   "file"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.string   "original_file_url"
    t.string   "identifier"
    t.integer  "instance_id"
    t.text     "transcript"
    t.string   "format"
    t.integer  "size",              :limit => 8
    t.integer  "storage_id"
    t.string   "path"
    t.time     "deleted_at"
    t.datetime "transcoded_at"
    t.integer  "duration"
    t.boolean  "metered"
    t.integer  "user_id"
    t.integer  "listens",                        :default => 0, :null => false
  end

  add_index "audio_files", ["item_id"], :name => "index_audio_files_on_item_id"

  create_table "collection_grants", :force => true do |t|
    t.integer  "collection_id"
    t.integer  "collector_id"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.boolean  "uploads_collection", :default => false
    t.string   "collector_type"
  end

  add_index "collection_grants", ["collection_id"], :name => "index_collection_grants_on_collection_id"
  add_index "collection_grants", ["collector_id", "collection_id"], :name => "index_collection_grants_on_user_id_and_collection_id", :unique => true
  add_index "collection_grants", ["collector_id"], :name => "index_collection_grants_on_user_id"

  create_table "collections", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.boolean  "items_visible_by_default", :default => false
    t.boolean  "copy_media"
    t.integer  "default_storage_id"
    t.integer  "upload_storage_id"
    t.datetime "deleted_at"
    t.integer  "creator_id"
  end

  create_table "contributions", :force => true do |t|
    t.integer  "person_id"
    t.integer  "item_id"
    t.string   "role"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "contributions", ["item_id"], :name => "index_contributions_on_item_id"
  add_index "contributions", ["person_id"], :name => "index_contributions_on_person_id"
  add_index "contributions", ["role", "item_id"], :name => "index_contributions_on_role_and_item_id"

  create_table "csv_imports", :force => true do |t|
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "file"
    t.integer  "state_index",   :default => 0
    t.string   "headers",                                      :array => true
    t.string   "file_name"
    t.integer  "collection_id", :default => 0
    t.string   "error_message"
    t.text     "backtrace"
    t.integer  "user_id"
  end

  add_index "csv_imports", ["user_id"], :name => "index_csv_imports_on_user_id"

  create_table "csv_rows", :force => true do |t|
    t.text     "values",                        :array => true
    t.integer  "csv_import_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "csv_rows", ["csv_import_id"], :name => "index_csv_rows_on_csv_import_id"

  create_table "entities", :force => true do |t|
    t.boolean  "is_confirmed"
    t.string   "identifier"
    t.string   "name"
    t.float    "score"
    t.string   "category"
    t.string   "entity_type"
    t.integer  "item_id"
    t.text     "extra"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "entities", ["is_confirmed", "item_id", "score"], :name => "index_entities_on_is_confirmed_and_item_id_and_score"
  add_index "entities", ["item_id"], :name => "index_entities_on_item_id"

  create_table "geolocations", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.decimal  "latitude"
    t.decimal  "longitude"
  end

  create_table "image_files", :force => true do |t|
    t.integer  "item_id"
    t.string   "file"
    t.boolean  "is_uploaded"
    t.string   "upload_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "import_mappings", :force => true do |t|
    t.string   "data_type"
    t.string   "column"
    t.integer  "csv_import_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "position"
  end

  add_index "import_mappings", ["csv_import_id"], :name => "index_import_mappings_on_csv_import_id"

  create_table "instances", :force => true do |t|
    t.string   "identifier"
    t.boolean  "digital"
    t.string   "location"
    t.string   "format"
    t.integer  "item_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "items", :force => true do |t|
    t.text     "title"
    t.text     "episode_title"
    t.text     "series_title"
    t.text     "description"
    t.text     "identifier"
    t.date     "date_broadcast"
    t.date     "date_created"
    t.text     "rights"
    t.text     "physical_format"
    t.text     "digital_format"
    t.text     "physical_location"
    t.text     "digital_location"
    t.integer  "duration"
    t.text     "music_sound_used"
    t.text     "date_peg"
    t.text     "notes"
    t.string   "tags",                              :array => true
    t.integer  "geolocation_id"
    t.hstore   "extra"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "csv_import_id"
    t.integer  "collection_id"
    t.string   "token"
    t.integer  "storage_id"
    t.boolean  "is_public"
    t.text     "transcription"
    t.string   "language"
    t.datetime "deleted_at"
    t.string   "image"
  end

  add_index "items", ["collection_id"], :name => "index_items_on_collection_id"
  add_index "items", ["csv_import_id"], :name => "index_items_on_csv_import_id"
  add_index "items", ["geolocation_id"], :name => "index_items_on_geolocation_id"

  create_table "oauth_access_grants", :force => true do |t|
    t.integer  "resource_owner_id", :null => false
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.integer  "expires_in",        :null => false
    t.string   "redirect_uri",      :null => false
    t.datetime "created_at",        :null => false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], :name => "index_oauth_access_grants_on_token", :unique => true

  create_table "oauth_access_tokens", :force => true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null => false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], :name => "index_oauth_access_tokens_on_refresh_token", :unique => true
  add_index "oauth_access_tokens", ["resource_owner_id"], :name => "index_oauth_access_tokens_on_resource_owner_id"
  add_index "oauth_access_tokens", ["token"], :name => "index_oauth_access_tokens_on_token", :unique => true

  create_table "oauth_applications", :force => true do |t|
    t.string   "name",         :null => false
    t.string   "uid",          :null => false
    t.string   "secret",       :null => false
    t.string   "redirect_uri", :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
  end

  add_index "oauth_applications", ["owner_id", "owner_type"], :name => "index_oauth_applications_on_owner_id_and_owner_type"
  add_index "oauth_applications", ["uid"], :name => "index_oauth_applications_on_uid", :unique => true

  create_table "organizations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "amara_key"
    t.string   "amara_username"
    t.string   "amara_team"
  end

  create_table "people", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], :name => "index_roles_on_name_and_resource_type_and_resource_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "storage_configurations", :force => true do |t|
    t.string   "provider"
    t.string   "key"
    t.string   "secret"
    t.string   "bucket"
    t.string   "region"
    t.boolean  "is_public"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "subscription_plans", :force => true do |t|
    t.integer  "pop_up_hours"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "stripe_plan_id"
  end

  create_table "tasks", :force => true do |t|
    t.integer  "owner_id"
    t.string   "owner_type"
    t.text     "identifier"
    t.string   "name"
    t.string   "status"
    t.hstore   "extras"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "type"
    t.integer  "storage_id"
  end

  add_index "tasks", ["identifier"], :name => "index_tasks_on_identifier"
  add_index "tasks", ["owner_id", "owner_type"], :name => "index_tasks_on_owner_id_and_owner_type"

  create_table "timed_texts", :force => true do |t|
    t.integer  "transcript_id"
    t.integer  "start_time"
    t.integer  "end_time"
    t.text     "text"
    t.decimal  "confidence"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "timed_texts", ["start_time", "transcript_id"], :name => "index_timed_texts_on_start_time_and_transcript_id"

  create_table "transcripts", :force => true do |t|
    t.integer  "audio_file_id"
    t.string   "identifier"
    t.string   "language"
    t.integer  "start_time"
    t.integer  "end_time"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.decimal  "confidence"
  end

  add_index "transcripts", ["audio_file_id", "identifier"], :name => "index_transcripts_on_audio_file_id_and_identifier"

  create_table "users", :force => true do |t|
    t.string   "email",                                       :default => "", :null => false
    t.string   "encrypted_password",                          :default => ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                               :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.integer  "default_public_collection_id"
    t.integer  "default_private_collection_id"
    t.string   "invitation_token",              :limit => 60
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "organization_id"
    t.string   "customer_id"
    t.integer  "pop_up_hours_cache"
    t.integer  "used_metered_storage_cache"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token", :unique => true
  add_index "users", ["invited_by_id"], :name => "index_users_on_invited_by_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_roles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"

end
