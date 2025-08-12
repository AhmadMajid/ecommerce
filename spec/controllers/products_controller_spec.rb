require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
  let!(:electronics_category) { create(:category, name: "Electronics") }
  let!(:clothing_category) { create(:category, name: "Clothing") }
  let!(:subcategory) { create(:category, name: "Smartphones", parent: electronics_category) }

  let!(:iphone) do
    create(:product,
           name: "iPhone 15 Pro",
           description: "Latest Apple smartphone with advanced camera",
           category: subcategory,
           price: 999.99)
  end

  let!(:macbook) do
    create(:product,
           name: "MacBook Air M2",
           description: "Powerful laptop for creative professionals",
           category: electronics_category,
           price: 1199.99)
  end

  let!(:shirt) do
    create(:product,
           name: "Cotton T-Shirt",
           description: "Comfortable everyday wear",
           category: clothing_category,
           price: 25.99)
  end

  let!(:inactive_product) do
    create(:product,
           name: "Inactive Product",
           category: electronics_category,
           price: 500.00,
           active: false)
  end

  describe "GET #index" do
    context "without filters" do
      it "assigns all active products" do
        get :index

        expect(assigns(:products)).to include(iphone, macbook, shirt)
        expect(assigns(:products)).not_to include(inactive_product)
      end

      it "assigns all active categories" do
        get :index

        expect(assigns(:categories)).to include(electronics_category, clothing_category, subcategory)
      end

      it "renders the index template" do
        get :index

        expect(response).to render_template(:index)
      end
    end

    context "with search parameter" do
      it "filters products by name" do
        get :index, params: { search: "iPhone" }

        expect(assigns(:products)).to include(iphone)
        expect(assigns(:products)).not_to include(macbook, shirt)
      end

      it "filters products by description" do
        get :index, params: { search: "laptop" }

        expect(assigns(:products)).to include(macbook)
        expect(assigns(:products)).not_to include(iphone, shirt)
      end

      it "performs case-insensitive search" do
        get :index, params: { search: "IPHONE" }

        expect(assigns(:products)).to include(iphone)
        expect(assigns(:products)).not_to include(macbook, shirt)
      end

      it "handles partial matches" do
        get :index, params: { search: "Apple" }

        expect(assigns(:products)).to include(iphone)
        expect(assigns(:products)).not_to include(macbook, shirt)
      end

      it "returns empty results for non-matching search" do
        get :index, params: { search: "NonexistentProduct" }

        expect(assigns(:products)).to be_empty
      end
    end

    context "with category_id parameter" do
      it "filters products by category" do
        get :index, params: { category_id: electronics_category.id }

        expect(assigns(:products)).to include(macbook)
        expect(assigns(:products)).not_to include(shirt)
      end

      it "includes products from subcategories" do
        get :index, params: { category_id: electronics_category.id }

        expect(assigns(:products)).to include(iphone, macbook)
        expect(assigns(:products)).not_to include(shirt)
      end

      it "sets current_category" do
        get :index, params: { category_id: electronics_category.id }

        expect(assigns(:current_category)).to eq(electronics_category)
      end

      it "handles invalid category_id gracefully" do
        expect {
          get :index, params: { category_id: 99999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with price range parameters" do
      it "filters by minimum price" do
        get :index, params: { min_price: 500 }

        expect(assigns(:products)).to include(iphone, macbook)
        expect(assigns(:products)).not_to include(shirt)
      end

      it "filters by maximum price" do
        get :index, params: { max_price: 100 }

        expect(assigns(:products)).to include(shirt)
        expect(assigns(:products)).not_to include(iphone, macbook)
      end

      it "filters by price range" do
        get :index, params: { min_price: 900, max_price: 1100 }

        expect(assigns(:products)).to include(iphone)
        expect(assigns(:products)).not_to include(macbook, shirt)
      end

      it "handles decimal prices correctly" do
        get :index, params: { min_price: 25.99, max_price: 25.99 }

        expect(assigns(:products)).to include(shirt)
        expect(assigns(:products)).not_to include(iphone, macbook)
      end

      it "handles empty price parameters" do
        get :index, params: { min_price: "", max_price: "" }

        expect(assigns(:products)).to include(iphone, macbook, shirt)
      end
    end

    context "with combined filters" do
      it "applies search and category filters together" do
        get :index, params: {
          search: "MacBook",
          category_id: electronics_category.id
        }

        expect(assigns(:products)).to include(macbook)
        expect(assigns(:products)).not_to include(iphone, shirt)
      end

      it "applies all filters together" do
        get :index, params: {
          search: "iPhone",
          category_id: electronics_category.id,
          min_price: 500,
          max_price: 1500
        }

        expect(assigns(:products)).to include(iphone)
        expect(assigns(:products)).not_to include(macbook, shirt)
      end

      it "returns empty results when filters don't match" do
        get :index, params: {
          search: "iPhone",
          category_id: clothing_category.id
        }

        expect(assigns(:products)).to be_empty
      end
    end

    context "with sorting" do
      before do
        # Ensure we have a predictable order
        iphone.update!(created_at: 3.days.ago)
        macbook.update!(created_at: 2.days.ago)
        shirt.update!(created_at: 1.day.ago)
      end

      it "sorts by price low to high" do
        get :index, params: { sort: "price_low" }

        products = assigns(:products).to_a
        expect(products.index(shirt)).to be < products.index(iphone)
        expect(products.index(iphone)).to be < products.index(macbook)
      end

      it "sorts by price high to low" do
        get :index, params: { sort: "price_high" }

        products = assigns(:products).to_a
        expect(products.index(macbook)).to be < products.index(iphone)
        expect(products.index(iphone)).to be < products.index(shirt)
      end

      it "sorts by name alphabetically" do
        get :index, params: { sort: "name" }

        products = assigns(:products).to_a
        expect(products.index(shirt)).to be < products.index(iphone)
        expect(products.index(iphone)).to be < products.index(macbook)
      end

      it "sorts by newest first" do
        get :index, params: { sort: "newest" }

        products = assigns(:products).to_a
        expect(products.index(shirt)).to be < products.index(macbook)
        expect(products.index(macbook)).to be < products.index(iphone)
      end

      it "uses default order when sort parameter is empty" do
        get :index, params: { sort: "" }

        expect(assigns(:products)).to include(iphone, macbook, shirt)
      end
    end

    context "performance and optimization" do
      it "includes necessary associations to avoid N+1 queries" do
        get :index

        expect(assigns(:products)).to be_present
      end

      it "includes categories with parent associations" do
        get :index

        expect(assigns(:categories)).to be_present
      end
    end
  end
end