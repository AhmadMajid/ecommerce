require 'rails_helper'

RSpec.describe "Products", type: :request do
  let!(:electronics_category) { create(:category, name: "Electronics") }
  let!(:clothing_category) { create(:category, name: "Clothing") }
  let!(:books_category) { create(:category, name: "Books") }

  let!(:iphone) do
    create(:product,
           name: "iPhone 15 Pro",
           description: "Latest Apple smartphone with advanced features",
           category: electronics_category,
           price: 999.99)
  end

  let!(:macbook) do
    create(:product,
           name: "MacBook Air",
           description: "Lightweight laptop for professionals",
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

  let!(:book) do
    create(:product,
           name: "Programming Ruby",
           description: "Complete guide to Ruby programming",
           category: books_category,
           price: 49.99)
  end

  describe "GET /products" do
    context "without any filters" do
      it "returns all active products" do
        get products_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).to include("MacBook Air")
        expect(response.body).to include("Cotton T-Shirt")
        expect(response.body).to include("Programming Ruby")
      end
    end

    context "with search filter" do
      it "filters products by name" do
        get products_path, params: { search: "iPhone" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).not_to include("MacBook Air")
        expect(response.body).not_to include("Cotton T-Shirt")
      end

      it "filters products by description" do
        get products_path, params: { search: "programming" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Programming Ruby")
        expect(response.body).not_to include("iPhone 15 Pro")
      end

      it "is case insensitive" do
        get products_path, params: { search: "IPHONE" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
      end

      it "handles partial matches" do
        get products_path, params: { search: "Apple" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
      end
    end

    context "with category filter" do
      it "filters products by category" do
        get products_path, params: { category_id: electronics_category.id }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).to include("MacBook Air")
        expect(response.body).not_to include("Cotton T-Shirt")
        expect(response.body).not_to include("Programming Ruby")
      end

      it "shows all products when category is cleared" do
        get products_path, params: { category_id: "" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).to include("Cotton T-Shirt")
      end
    end

    context "with price range filter" do
      it "filters products by minimum price" do
        get products_path, params: { min_price: 500 }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).to include("MacBook Air")
        expect(response.body).not_to include("Cotton T-Shirt")
        expect(response.body).not_to include("Programming Ruby")
      end

      it "filters products by maximum price" do
        get products_path, params: { max_price: 100 }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Cotton T-Shirt")
        expect(response.body).to include("Programming Ruby")
        expect(response.body).not_to include("iPhone 15 Pro")
        expect(response.body).not_to include("MacBook Air")
      end

      it "filters products by price range" do
        get products_path, params: { min_price: 40, max_price: 60 }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Programming Ruby")
        expect(response.body).not_to include("Cotton T-Shirt")
        expect(response.body).not_to include("iPhone 15 Pro")
      end
    end

    context "with combined filters" do
      it "applies multiple filters together" do
        get products_path, params: {
          search: "Mac",
          category_id: electronics_category.id,
          min_price: 1000
        }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("MacBook Air")
        expect(response.body).not_to include("iPhone 15 Pro")
        expect(response.body).not_to include("Cotton T-Shirt")
      end

      it "returns no results when filters don't match any products" do
        get products_path, params: {
          search: "Nonexistent",
          category_id: electronics_category.id
        }

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("iPhone 15 Pro")
        expect(response.body).not_to include("MacBook Air")
      end
    end

    context "with sorting" do
      it "sorts by price low to high" do
        get products_path, params: { sort: "price_low" }

        expect(response).to have_http_status(:success)
        # Check that products appear in price order
        expect(response.body.index("Cotton T-Shirt")).to be < response.body.index("Programming Ruby")
        expect(response.body.index("Programming Ruby")).to be < response.body.index("iPhone 15 Pro")
      end

      it "sorts by price high to low" do
        get products_path, params: { sort: "price_high" }

        expect(response).to have_http_status(:success)
        # Check that products appear in reverse price order
        expect(response.body.index("MacBook Air")).to be < response.body.index("iPhone 15 Pro")
        expect(response.body.index("iPhone 15 Pro")).to be < response.body.index("Programming Ruby")
      end

      it "sorts by name" do
        get products_path, params: { sort: "name" }

        expect(response).to have_http_status(:success)
        # Check alphabetical order
        expect(response.body.index("Cotton T-Shirt")).to be < response.body.index("iPhone 15 Pro")
        expect(response.body.index("iPhone 15 Pro")).to be < response.body.index("MacBook Air")
      end
    end

    context "preserving filters across actions" do
      it "maintains search when changing sort" do
        get products_path, params: {
          search: "iPhone",
          sort: "price_high"
        }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).not_to include("MacBook Air")
      end

      it "maintains category filter when changing sort" do
        get products_path, params: {
          category_id: electronics_category.id,
          sort: "name"
        }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).to include("MacBook Air")
        expect(response.body).not_to include("Cotton T-Shirt")
      end
    end
  end

  describe "GET /categories/:id" do
    it "shows products from the specific category" do
      get category_path(electronics_category)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("iPhone 15 Pro")
      expect(response.body).to include("MacBook Air")
      expect(response.body).not_to include("Cotton T-Shirt")
    end

    it "allows filtering within category" do
      get category_path(electronics_category), params: { search: "iPhone" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("iPhone 15 Pro")
      expect(response.body).not_to include("MacBook Air")
    end

    it "shows category filter dropdown even when viewing specific category" do
      get category_path(electronics_category)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("All Categories")
      expect(response.body).to include("Category")
    end
  end
end
