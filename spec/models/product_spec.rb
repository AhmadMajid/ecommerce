require 'rails_helper'

RSpec.describe Product, type: :model do
  let!(:electronics_category) { create(:category, name: "Electronics") }
  let!(:clothing_category) { create(:category, name: "Clothing") }
  let!(:subcategory) { create(:category, name: "Smartphones", parent: electronics_category) }

  let!(:active_product) do
    create(:product,
           name: "iPhone 15 Pro",
           category: electronics_category,
           price: 999.99,
           active: true)
  end

  let!(:inactive_product) do
    create(:product,
           name: "Old Phone",
           category: electronics_category,
           price: 299.99,
           active: false)
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active products" do
        expect(Product.active).to include(active_product)
        expect(Product.active).not_to include(inactive_product)
      end
    end

    describe ".inactive" do
      it "returns only inactive products" do
        expect(Product.inactive).to include(inactive_product)
        expect(Product.inactive).not_to include(active_product)
      end
    end

    describe ".available" do
      let!(:published_product) do
        create(:product,
               active: true,
               published_at: 1.day.ago)
      end

      let!(:unpublished_product) do
        create(:product,
               active: true,
               published_at: nil)
      end

      it "returns active and published products" do
        expect(Product.available).to include(published_product)
        expect(Product.available).not_to include(unpublished_product, inactive_product)
      end
    end
  end

  describe "filtering methods" do
    let!(:iphone) do
      create(:product,
             name: "iPhone 15 Pro",
             description: "Latest Apple smartphone with advanced camera",
             category: electronics_category,
             price: 999.99,
             active: true)
    end

    let!(:macbook) do
      create(:product,
             name: "MacBook Air",
             description: "Lightweight laptop for professionals",
             category: electronics_category,
             price: 1199.99,
             active: true)
    end

    let!(:shirt) do
      create(:product,
             name: "Cotton T-Shirt",
             description: "Comfortable everyday wear",
             category: clothing_category,
             price: 25.99,
             active: true)
    end

    describe "search filtering" do
      it "finds products by name using ILIKE" do
        results = Product.where("name ILIKE ?", "%iPhone%")

        expect(results).to include(iphone)
        expect(results).not_to include(macbook, shirt)
      end

      it "finds products by description using ILIKE" do
        results = Product.where("description ILIKE ?", "%laptop%")

        expect(results).to include(macbook)
        expect(results).not_to include(iphone, shirt)
      end

      it "performs case-insensitive search" do
        results = Product.where("name ILIKE ? OR description ILIKE ?", "%IPHONE%", "%IPHONE%")

        expect(results).to include(iphone)
        expect(results).not_to include(macbook, shirt)
      end

      it "handles partial matches" do
        results = Product.where("name ILIKE ? OR description ILIKE ?", "%Apple%", "%Apple%")

        expect(results).to include(iphone)
        expect(results).not_to include(macbook, shirt)
      end
    end

    describe "category filtering" do
      it "filters by specific category" do
        results = Product.where(category_id: electronics_category.id)

        expect(results).to include(iphone, macbook)
        expect(results).not_to include(shirt)
      end

      it "filters by multiple categories" do
        results = Product.where(category_id: [electronics_category.id, clothing_category.id])

        expect(results).to include(iphone, macbook, shirt)
      end
    end

    describe "price range filtering" do
      it "filters by minimum price" do
        results = Product.where("price >= ?", 500)

        expect(results).to include(iphone, macbook)
        expect(results).not_to include(shirt)
      end

      it "filters by maximum price" do
        results = Product.where("price <= ?", 100)

        expect(results).to include(shirt)
        expect(results).not_to include(iphone, macbook)
      end

      it "filters by price range" do
        results = Product.where("price >= ? AND price <= ?", 900, 1100)

        expect(results).to include(iphone)
        expect(results).not_to include(macbook, shirt)
      end

      it "handles decimal price values" do
        results = Product.where("price >= ? AND price <= ?", 25.99, 25.99)

        expect(results).to include(shirt)
        expect(results).not_to include(iphone, macbook)
      end
    end
  end

  describe "associations for filtering" do
    it "belongs to category" do
      expect(active_product.category).to eq(electronics_category)
    end

    it "can access category name for display" do
      expect(active_product.category.name).to eq("Electronics")
    end
  end

  describe "validation and constraints" do
    it "requires a category" do
      product = build(:product, category: nil)

      expect(product).not_to be_valid
      expect(product.errors[:category]).to include("must exist")
    end

    it "requires a price" do
      product = build(:product, price: nil)

      expect(product).not_to be_valid
      expect(product.errors[:price]).to be_present
    end

    it "validates price is positive" do
      product = build(:product, price: -10)

      expect(product).not_to be_valid
    end
  end

  describe "database indexes for performance" do
    it "has proper indexes for filtering queries" do
      # These tests would verify database indexes exist for:
      # - active column
      # - category_id column
      # - price column
      # - name column (for search)
      # - description column (for search)
      # This helps ensure filtering queries perform well

      expect(ActiveRecord::Base.connection.indexes('products').map(&:columns).flatten).to include('category_id')
    end
  end

  describe "stock status methods" do
    let!(:in_stock_product) do
      create(:product,
             track_inventory: true,
             inventory_quantity: 10)
    end

    let!(:out_of_stock_product) do
      create(:product,
             track_inventory: true,
             inventory_quantity: 0)
    end

    let!(:no_tracking_product) do
      create(:product,
             track_inventory: false)
    end

    it "correctly identifies stock status" do
      expect(in_stock_product.stock_status).to eq('in_stock')
      expect(out_of_stock_product.stock_status).to eq('out_of_stock')
    end

    it "handles products without inventory tracking" do
      expect(no_tracking_product.track_inventory?).to be_falsey
    end
  end
end
