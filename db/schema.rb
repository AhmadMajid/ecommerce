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

ActiveRecord::Schema[8.0].define(version: 2025_08_11_181516) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "address_type", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "company"
    t.string "address_line_1", null: false
    t.string "address_line_2"
    t.string "city", null: false
    t.string "state_province", null: false
    t.string "postal_code", null: false
    t.string "country", default: "US", null: false
    t.string "phone"
    t.boolean "default_address", default: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_addresses_on_active"
    t.index ["user_id", "address_type"], name: "index_addresses_on_user_id_and_address_type"
    t.index ["user_id", "default_address"], name: "index_addresses_on_user_id_and_default_address"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "product_name"
    t.json "product_options"
    t.text "custom_attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["created_at"], name: "index_cart_items_on_created_at"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "user_id"
    t.string "session_id"
    t.integer "status", default: 0
    t.datetime "expires_at"
    t.string "currency", default: "USD"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "shipping_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "total", precision: 10, scale: 2, default: "0.0"
    t.string "coupon_code"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_carts_on_created_at"
    t.index ["expires_at"], name: "index_carts_on_expires_at"
    t.index ["session_id", "status"], name: "index_carts_on_session_id_and_status"
    t.index ["session_id"], name: "index_carts_on_session_id"
    t.index ["status"], name: "index_carts_on_status"
    t.index ["user_id", "status"], name: "index_carts_on_user_id_and_status"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "slug", null: false
    t.string "meta_title"
    t.text "meta_description"
    t.bigint "parent_id"
    t.integer "position", default: 0
    t.boolean "active", default: true, null: false
    t.boolean "featured", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "featured"], name: "index_categories_on_active_and_featured"
    t.index ["active"], name: "index_categories_on_active"
    t.index ["featured"], name: "index_categories_on_featured"
    t.index ["parent_id", "position"], name: "index_categories_on_parent_id_and_position"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "checkouts", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "cart_id", null: false
    t.json "shipping_address"
    t.json "billing_address"
    t.bigint "shipping_method_id"
    t.string "payment_method"
    t.string "status", default: "started", null: false
    t.string "session_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.decimal "subtotal", precision: 10, scale: 2
    t.decimal "tax_amount", precision: 10, scale: 2
    t.decimal "shipping_amount", precision: 10, scale: 2
    t.decimal "discount_amount", precision: 10, scale: 2
    t.text "notes"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at"
    t.index ["cart_id"], name: "index_checkouts_on_cart_id"
    t.index ["expires_at"], name: "index_checkouts_on_expires_at"
    t.index ["session_id", "status"], name: "index_checkouts_on_session_id_and_status"
    t.index ["shipping_method_id"], name: "index_checkouts_on_shipping_method_id"
    t.index ["user_id", "status"], name: "index_checkouts_on_user_id_and_status"
    t.index ["user_id"], name: "index_checkouts_on_user_id"
  end

  create_table "product_variants", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "title", null: false
    t.string "sku", null: false
    t.string "barcode"
    t.decimal "price", precision: 10, scale: 2
    t.decimal "compare_at_price", precision: 10, scale: 2
    t.decimal "cost_price", precision: 10, scale: 2
    t.integer "inventory_quantity", default: 0
    t.boolean "track_inventory", default: true
    t.boolean "allow_backorder", default: false
    t.decimal "weight", precision: 8, scale: 2
    t.string "weight_unit", default: "kg"
    t.json "dimensions"
    t.string "option1_name"
    t.string "option1_value"
    t.string "option2_name"
    t.string "option2_value"
    t.string "option3_name"
    t.string "option3_value"
    t.boolean "active", default: true
    t.integer "position", default: 0
    t.boolean "requires_shipping", default: true
    t.boolean "taxable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_product_variants_on_active"
    t.index ["inventory_quantity"], name: "index_product_variants_on_inventory_quantity"
    t.index ["option1_name", "option1_value"], name: "index_product_variants_on_option1_name_and_option1_value"
    t.index ["option2_name", "option2_value"], name: "index_product_variants_on_option2_name_and_option2_value"
    t.index ["option3_name", "option3_value"], name: "index_product_variants_on_option3_name_and_option3_value"
    t.index ["price"], name: "index_product_variants_on_price"
    t.index ["product_id", "active"], name: "index_product_variants_on_product_id_and_active"
    t.index ["product_id", "position"], name: "index_product_variants_on_product_id_and_position"
    t.index ["product_id"], name: "index_product_variants_on_product_id"
    t.index ["sku"], name: "index_product_variants_on_sku", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "short_description"
    t.string "sku", null: false
    t.string "slug", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.decimal "compare_at_price", precision: 10, scale: 2
    t.decimal "cost_price", precision: 10, scale: 2
    t.decimal "weight", precision: 8, scale: 3
    t.decimal "length", precision: 8, scale: 3
    t.decimal "width", precision: 8, scale: 3
    t.decimal "height", precision: 8, scale: 3
    t.integer "inventory_quantity", default: 0
    t.boolean "track_inventory", default: true, null: false
    t.boolean "allow_backorders", default: false, null: false
    t.integer "low_stock_threshold", default: 5
    t.boolean "active", default: true, null: false
    t.boolean "featured", default: false, null: false
    t.datetime "published_at"
    t.string "meta_title"
    t.text "meta_description"
    t.text "meta_keywords"
    t.bigint "category_id", null: false
    t.boolean "taxable", default: true, null: false
    t.boolean "requires_shipping", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "featured"], name: "index_products_on_active_and_featured"
    t.index ["active", "published_at"], name: "index_products_on_active_and_published_at"
    t.index ["active"], name: "index_products_on_active"
    t.index ["category_id", "active"], name: "index_products_on_category_id_and_active"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["inventory_quantity"], name: "index_products_on_inventory_quantity"
    t.index ["published_at"], name: "index_products_on_published_at"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["track_inventory", "inventory_quantity"], name: "index_products_on_track_inventory_and_inventory_quantity"
  end

  create_table "shipping_methods", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "carrier", null: false
    t.decimal "base_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "cost_per_kg", precision: 10, scale: 2
    t.integer "min_delivery_days", null: false
    t.integer "max_delivery_days", null: false
    t.decimal "free_shipping_threshold", precision: 10, scale: 2
    t.boolean "active", default: true, null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "sort_order"], name: "index_shipping_methods_on_active_and_sort_order"
    t.index ["active"], name: "index_shipping_methods_on_active"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.date "date_of_birth"
    t.integer "role", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "role"], name: "index_users_on_active_and_role"
    t.index ["active"], name: "index_users_on_active"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "users"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "checkouts", "carts"
  add_foreign_key "checkouts", "shipping_methods"
  add_foreign_key "checkouts", "users"
  add_foreign_key "product_variants", "products"
  add_foreign_key "products", "categories"
end
