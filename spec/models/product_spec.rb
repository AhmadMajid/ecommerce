require 'rails_helper'

RSpec.describe Product, type: :model do
  let!(:electronics_category) { create(:category, name: "Electronics") }
  let!(:clothing_category) { create(:category, name: "Clothing") }

  describe "validation" do
    it "is valid with valid attributes" do
      product = build(:product, category: electronics_category)
      expect(product).to be_valid
    end

    it "requires a name" do
      product = build(:product, name: nil, category: electronics_category)
      expect(product).not_to be_valid
      expect(product.errors[:name]).to include("can't be blank")
    end

    it "requires a price" do
      product = build(:product, price: nil, category: electronics_category)
      expect(product).not_to be_valid
      expect(product.errors[:price]).to include("can't be blank")
    end

    it "requires price to be positive" do
      product = build(:product, price: -1, category: electronics_category)
      expect(product).not_to be_valid
      expect(product.errors[:price]).to include("must be greater than 0")
    end

    it "requires unique slug" do
      create(:product, name: "Test Product", category: electronics_category)
      duplicate = build(:product, name: "Test Product", category: clothing_category)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end
  end

  describe "scopes" do
    let!(:active_published_product) do
      create(:product,
             name: "Active Published Product",
             active: true,
             published_at: 1.day.ago,
             category: electronics_category)
    end

    let!(:inactive_product) do
      create(:product,
             name: "Inactive Product",
             active: false,
             published_at: 1.day.ago,
             category: electronics_category)
    end

    let!(:unpublished_product) do
      create(:product,
             name: "Unpublished Product",
             active: true,
             published_at: nil,
             category: electronics_category)
    end

    describe ".available" do
      it "returns active and published products" do
        expect(Product.available).to include(active_published_product)
        expect(Product.available).not_to include(unpublished_product, inactive_product)
      end
    end
  end

  describe "filtering methods" do
    describe "search filtering" do
      it "finds products by name" do
        iphone = create(:product,
                       name: "iPhone Test Search",
                       description: "Smartphone",
                       category: electronics_category,
                       active: true)

        results = Product.where("name ILIKE ?", "%iPhone%")
        expect(results).to include(iphone)
      end

      it "finds products by description" do
        product = create(:product,
                        name: "Smartphone",
                        description: "Latest Apple technology",
                        category: electronics_category,
                        active: true)

        results = Product.where("description ILIKE ?", "%Apple%")
        expect(results).to include(product)
      end
    end

    describe "category filtering" do
      it "filters by specific category" do
        electronics_product = create(:product,
                                    name: "Electronics Product",
                                    category: electronics_category)

        clothing_product = create(:product,
                                 name: "Clothing Product",
                                 category: clothing_category)

        results = Product.where(category_id: electronics_category.id)
        expect(results).to include(electronics_product)
        expect(results).not_to include(clothing_product)
      end
    end

    describe "price range filtering" do
      it "filters by minimum price" do
        cheap_product = create(:product,
                              name: "Cheap Product",
                              price: 10.00,
                              category: electronics_category)

        expensive_product = create(:product,
                                  name: "Expensive Product",
                                  price: 1000.00,
                                  category: electronics_category)

        results = Product.where("price >= ?", 500)
        expect(results).to include(expensive_product)
        expect(results).not_to include(cheap_product)
      end

      it "filters by maximum price" do
        cheap_product = create(:product,
                              name: "Cheap Product 2",
                              price: 10.00,
                              category: electronics_category)

        expensive_product = create(:product,
                                  name: "Expensive Product 2",
                                  price: 1000.00,
                                  category: electronics_category)

        results = Product.where("price <= ?", 100)
        expect(results).to include(cheap_product)
        expect(results).not_to include(expensive_product)
      end
    end
  end

  describe 'associations' do
    it { should have_many(:wishlists).dependent(:destroy) }
    it { should have_many(:reviews).dependent(:destroy) }
  end

  describe 'review and rating methods' do
    let!(:product) { create(:product, category: electronics_category) }
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }

    context 'with reviews' do
      before do
        create(:review, product: product, user: user1, rating: 5)
        create(:review, product: product, user: user2, rating: 3)
        create(:review, product: product, user: user3, rating: 4)
      end

      describe '#average_rating' do
        it 'calculates the correct average rating' do
          expect(product.average_rating).to eq(4.0)
        end

        it 'rounds to one decimal place' do
          create(:user).tap do |user4|
            create(:review, product: product, user: user4, rating: 2)
          end
          product.reload
          expect(product.average_rating).to eq(3.5)
        end
      end

      describe '#reviews_count' do
        it 'returns the correct number of reviews' do
          expect(product.reviews_count).to eq(3)
        end
      end
    end

    context 'without reviews' do
      describe '#average_rating' do
        it 'returns 0 when no reviews exist' do
          expect(product.average_rating).to eq(0)
        end
      end

      describe '#reviews_count' do
        it 'returns 0 when no reviews exist' do
          expect(product.reviews_count).to eq(0)
        end
      end
    end
  end

  describe 'sale percentage calculation' do
    let!(:product) { create(:product, category: electronics_category) }

    context 'with compare_at_price' do
      it 'calculates correct sale percentage' do
        product.update(price: 80.00, compare_at_price: 100.00)
        expect(product.sale_percentage).to eq(20.0)
      end

      it 'rounds to two decimal places' do
        product.update(price: 33.33, compare_at_price: 50.00)
        expect(product.sale_percentage).to eq(33.34)
      end
    end

    context 'without compare_at_price' do
      it 'returns 0 when no compare_at_price' do
        product.update(price: 80.00, compare_at_price: nil)
        expect(product.sale_percentage).to eq(0)
      end
    end
  end
end
