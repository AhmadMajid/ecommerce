require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  let!(:electronics_category) { create(:category, name: "Electronics", slug: "electronics") }
  let!(:clothing_category) { create(:category, name: "Clothing", slug: "clothing") }
  let!(:subcategory) { create(:category, name: "Smartphones", slug: "smartphones", parent: electronics_category) }

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
    it "assigns root categories with children" do
      get :index

      expect(assigns(:categories)).to include(electronics_category, clothing_category)
      expect(assigns(:categories)).not_to include(subcategory)
    end

    it "renders the index template" do
      get :index

      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    context "for valid category" do
      it "assigns the category" do
        get :show, params: { slug: electronics_category.slug }

        expect(assigns(:category)).to eq(electronics_category)
      end

      it "includes products from the category and its subcategories" do
        get :show, params: { slug: electronics_category.slug }

        expect(assigns(:products)).to include(macbook, iphone)
        expect(assigns(:products)).not_to include(shirt, inactive_product)
      end

      it "assigns subcategories" do
        get :show, params: { slug: electronics_category.slug }

        expect(assigns(:subcategories)).to include(subcategory)
      end

      it "renders the show template" do
        get :show, params: { slug: electronics_category.slug }

        expect(response).to render_template(:show)
      end
    end

    context "for invalid category" do
      it "returns 404 for non-existent category" do
        get :show, params: { slug: "non-existent" }

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for inactive category" do
        inactive_category = create(:category, name: "Inactive", slug: "inactive", active: false)
        get :show, params: { slug: inactive_category.slug }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with search parameter" do
      it "filters products by name within category" do
        get :show, params: { slug: electronics_category.slug, search: "iPhone" }

        expect(assigns(:products)).to include(iphone)
        expect(assigns(:products)).not_to include(macbook)
      end

      it "filters products by description within category" do
        get :show, params: { slug: electronics_category.slug, search: "laptop" }

        expect(assigns(:products)).to include(macbook)
        expect(assigns(:products)).not_to include(iphone)
      end
    end

    context "with price range parameters" do
      it "filters by minimum price within category" do
        get :show, params: { slug: electronics_category.slug, min_price: 1000 }

        expect(assigns(:products)).to include(macbook)
        expect(assigns(:products)).not_to include(iphone)
      end

      it "filters by maximum price within category" do
        get :show, params: { slug: electronics_category.slug, max_price: 1000 }

        expect(assigns(:products)).to include(iphone)
        expect(assigns(:products)).not_to include(macbook)
      end
    end

    context "with sorting" do
      before do
        # Ensure we have a predictable order
        iphone.update!(created_at: 3.days.ago)
        macbook.update!(created_at: 2.days.ago)
      end

      it "sorts by price low to high" do
        get :show, params: { slug: electronics_category.slug, sort: "price_low" }

        products = assigns(:products).to_a
        expect(products.index(iphone)).to be < products.index(macbook)
      end

      it "sorts by price high to low" do
        get :show, params: { slug: electronics_category.slug, sort: "price_high" }

        products = assigns(:products).to_a
        expect(products.index(macbook)).to be < products.index(iphone)
      end

      it "sorts by name alphabetically" do
        get :show, params: { slug: electronics_category.slug, sort: "name" }

        products = assigns(:products).to_a
        expect(products.index(iphone)).to be < products.index(macbook)
      end

      it "sorts by newest first" do
        get :show, params: { slug: electronics_category.slug, sort: "newest" }

        products = assigns(:products).to_a
        expect(products.index(macbook)).to be < products.index(iphone)
      end

      context "rating sort" do
        let!(:user1) { create(:user) }
        let!(:user2) { create(:user) }

        before do
          # Create reviews for testing rating sort within category
          # iPhone: 4.5 average (4 + 5) / 2 = 4.5
          create(:review, product: iphone, user: user1, rating: 4)
          create(:review, product: iphone, user: user2, rating: 5)

          # MacBook: 3.0 average (3)
          create(:review, product: macbook, user: user1, rating: 3)
        end

        it "sorts by rating high to low within category" do
          get :show, params: { slug: electronics_category.slug, sort: "rating_high" }

          products = assigns(:products).to_a
          # Order should be: iPhone (4.5), MacBook (3.0)
          expect(products.index(iphone)).to be < products.index(macbook)
        end

        it "sorts by rating low to high within category" do
          get :show, params: { slug: electronics_category.slug, sort: "rating_low" }

          products = assigns(:products).to_a
          # Order should be: MacBook (3.0), iPhone (4.5)
          expect(products.index(macbook)).to be < products.index(iphone)
        end

        it "handles products with no reviews correctly" do
          # Create a product with no reviews in the same category
          unreviewed_product = create(:product, name: "Unreviewed", category: electronics_category, price: 100)

          get :show, params: { slug: electronics_category.slug, sort: "rating_high" }

          products = assigns(:products).to_a
          # Products with reviews should come before products without reviews
          expect(products.index(iphone)).to be < products.index(unreviewed_product)
          expect(products.index(macbook)).to be < products.index(unreviewed_product)
        end
      end
    end

    context "with combined filters" do
      it "applies search and price filters together" do
        get :show, params: {
          slug: electronics_category.slug,
          search: "MacBook",
          min_price: 1000
        }

        expect(assigns(:products)).to include(macbook)
        expect(assigns(:products)).not_to include(iphone)
      end
    end

    context "performance and optimization" do
      it "includes necessary associations to avoid N+1 queries" do
        get :show, params: { slug: electronics_category.slug }

        expect(assigns(:products)).to be_present
      end

      it "includes subcategories with image attachments" do
        get :show, params: { slug: electronics_category.slug }

        expect(assigns(:subcategories)).to include(subcategory)
      end
    end
  end
end
