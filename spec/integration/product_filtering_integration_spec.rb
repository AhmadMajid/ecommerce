require 'rails_helper'

RSpec.describe "Product Filtering Integration", type: :request do
  let!(:electronics_category) { create(:category, name: "Electronics") }
  let!(:clothing_category) { create(:category, name: "Clothing") }

  let!(:iphone) do
    create(:product,
           name: "iPhone 15 Pro",
           description: "Latest Apple smartphone",
           category: electronics_category,
           price: 999.99,
           slug: "iphone-15-pro-test")
  end

  let!(:macbook) do
    create(:product,
           name: "MacBook Air",
           description: "Lightweight laptop",
           category: electronics_category,
           price: 1199.99,
           slug: "macbook-air-test")
  end

  let!(:shirt) do
    create(:product,
           name: "Cotton T-Shirt",
           description: "Comfortable clothing",
           category: clothing_category,
           price: 25.99,
           slug: "cotton-t-shirt-test")
  end

  describe "Product filtering functionality" do
    context "search filtering" do
      it "works correctly" do
        get products_path, params: { search: "iPhone" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).not_to include("MacBook Air")
      end
    end

    context "category filtering" do
      it "works correctly" do
        get products_path, params: { category_id: electronics_category.id }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).to include("MacBook Air")
        expect(response.body).not_to include("Cotton T-Shirt")
      end

      it "allows clearing category filter" do
        get products_path, params: { category_id: "" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).to include("Cotton T-Shirt")
      end
    end

    context "price filtering" do
      it "filters by minimum price" do
        get products_path, params: { min_price: 500 }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).to include("MacBook Air")
        expect(response.body).not_to include("Cotton T-Shirt")
      end

      it "filters by maximum price" do
        get products_path, params: { max_price: 100 }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Cotton T-Shirt")
        expect(response.body).not_to include("iPhone 15 Pro")
      end
    end

    context "combined filtering" do
      it "applies multiple filters" do
        get products_path, params: {
          search: "MacBook",
          category_id: electronics_category.id,
          min_price: 1000
        }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("MacBook Air")
        expect(response.body).not_to include("iPhone 15 Pro")
        expect(response.body).not_to include("Cotton T-Shirt")
      end
    end

    context "category page filtering" do
      it "shows category filter dropdown" do
        get category_path(electronics_category)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("All Categories")
        expect(response.body).to include("Category")
      end

      it "allows filtering within category" do
        get category_path(electronics_category), params: { search: "iPhone" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("iPhone 15 Pro")
        expect(response.body).not_to include("MacBook Air")
      end
    end
  end

  describe "Star rating display" do
    it "shows star ratings in product cards" do
      get products_path

      expect(response).to have_http_status(:success)
      # Check for horizontal star layout classes
      expect(response.body).to include('rating-stars mt-2 flex items-center')
      # Check for outlined stars
      expect(response.body).to include('fill="none"')
      expect(response.body).to include('stroke="currentColor"')
    end
  end

  describe "Filter form functionality" do
    it "shows filter form elements" do
      get products_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('name="search"')
      expect(response.body).to include('name="category_id"')
      expect(response.body).to include('name="min_price"')
      expect(response.body).to include('name="max_price"')
      expect(response.body).to include('type="submit"')
    end

    it "preserves filter values" do
      get products_path, params: {
        search: "iPhone",
        category_id: electronics_category.id,
        min_price: 500,
        max_price: 1500
      }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('value="iPhone"')
      expect(response.body).to include('value="500"')
      expect(response.body).to include('value="1500"')
    end
  end
end
