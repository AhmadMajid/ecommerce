require 'rails_helper'

RSpec.describe "Product Filtering UI", type: :system do
  let!(:electronics_category) { create(:category, name: "Electronics") }
  let!(:clothing_category) { create(:category, name: "Clothing") }

  let!(:iphone) do
    create(:product,
           name: "iPhone 15 Pro",
           description: "Latest Apple smartphone",
           category: electronics_category,
           price: 999.99)
  end

  let!(:macbook) do
    create(:product,
           name: "MacBook Air",
           description: "Lightweight laptop",
           category: electronics_category,
           price: 1199.99)
  end

  let!(:shirt) do
    create(:product,
           name: "Cotton T-Shirt",
           description: "Comfortable clothing",
           category: clothing_category,
           price: 25.99)
  end

  before do
    visit products_path
  end

  describe "Search functionality" do
    it "filters products by search term" do
      fill_in "Search", with: "iPhone"
      click_button "Filter"

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).not_to have_content("MacBook Air")
      expect(page).not_to have_content("Cotton T-Shirt")
    end

    it "shows no results message for non-existent products" do
      fill_in "Search", with: "NonexistentProduct"
      click_button "Filter"

      expect(page).not_to have_content("iPhone 15 Pro")
      expect(page).not_to have_content("MacBook Air")
    end

    it "clears search results when clear button is clicked" do
      fill_in "Search", with: "iPhone"
      click_button "Filter"

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).not_to have_content("MacBook Air")

      click_link "Clear"

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).to have_content("MacBook Air")
      expect(page).to have_content("Cotton T-Shirt")
    end
  end

  describe "Category filtering" do
    it "filters products by category selection" do
      select "Electronics", from: "Category"
      click_button "Filter"

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).to have_content("MacBook Air")
      expect(page).not_to have_content("Cotton T-Shirt")
    end

    it "shows all products when 'All Categories' is selected" do
      select "Electronics", from: "Category"
      click_button "Filter"

      expect(page).not_to have_content("Cotton T-Shirt")

      select "All Categories", from: "Category"
      click_button "Filter"

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).to have_content("MacBook Air")
      expect(page).to have_content("Cotton T-Shirt")
    end

    it "allows deselecting category even when viewing category page" do
      visit category_path(electronics_category)

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).not_to have_content("Cotton T-Shirt")

      select "All Categories", from: "Category"
      click_button "Filter"

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).to have_content("Cotton T-Shirt")
    end
  end

  describe "Price range filtering" do
    it "filters by minimum price" do
      fill_in "Min", with: "500"
      click_button "Filter"

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).to have_content("MacBook Air")
      expect(page).not_to have_content("Cotton T-Shirt")
    end

    it "filters by maximum price" do
      fill_in "Max", with: "100"
      click_button "Filter"

      expect(page).to have_content("Cotton T-Shirt")
      expect(page).not_to have_content("iPhone 15 Pro")
      expect(page).not_to have_content("MacBook Air")
    end

    it "filters by price range" do
      fill_in "Min", with: "900"
      fill_in "Max", with: "1100"
      click_button "Filter"

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).not_to have_content("MacBook Air")
      expect(page).not_to have_content("Cotton T-Shirt")
    end
  end

  describe "Combined filtering" do
    it "applies search and category filters together" do
      fill_in "Search", with: "Mac"
      select "Electronics", from: "Category"
      click_button "Filter"

      expect(page).to have_content("MacBook Air")
      expect(page).not_to have_content("iPhone 15 Pro")
      expect(page).not_to have_content("Cotton T-Shirt")
    end

    it "applies all filters together" do
      fill_in "Search", with: "Air"
      select "Electronics", from: "Category"
      fill_in "Min", with: "1000"
      click_button "Filter"

      expect(page).to have_content("MacBook Air")
      expect(page).not_to have_content("iPhone 15 Pro")
      expect(page).not_to have_content("Cotton T-Shirt")
    end
  end

  describe "Sorting functionality" do
    it "sorts products by price low to high" do
      select "Price: Low to High", from: "Sort by:"

      products = page.all('.product-card h3').map(&:text)
      expect(products.index("Cotton T-Shirt")).to be < products.index("iPhone 15 Pro")
    end

    it "sorts products by price high to low" do
      select "Price: High to Low", from: "Sort by:"

      products = page.all('.product-card h3').map(&:text)
      expect(products.index("MacBook Air")).to be < products.index("Cotton T-Shirt")
    end

    it "maintains filters when sorting" do
      select "Electronics", from: "Category"
      click_button "Filter"

      expect(page).not_to have_content("Cotton T-Shirt")

      select "Price: High to Low", from: "Sort by:"

      expect(page).to have_content("iPhone 15 Pro")
      expect(page).to have_content("MacBook Air")
      expect(page).not_to have_content("Cotton T-Shirt")
    end
  end

  describe "Filter form UI elements" do
    it "displays all filter controls" do
      expect(page).to have_field("Search")
      expect(page).to have_select("Category")
      expect(page).to have_field("Min")
      expect(page).to have_field("Max")
      expect(page).to have_button("Filter")
      expect(page).to have_link("Clear")
    end

    it "preserves filter values after form submission" do
      fill_in "Search", with: "iPhone"
      select "Electronics", from: "Category"
      fill_in "Min", with: "500"
      fill_in "Max", with: "1500"
      click_button "Filter"

      expect(page).to have_field("Search", with: "iPhone")
      expect(page).to have_select("Category", selected: "Electronics")
      expect(page).to have_field("Min", with: "500")
      expect(page).to have_field("Max", with: "1500")
    end

    it "shows category filter even when viewing specific category" do
      visit category_path(electronics_category)

      expect(page).to have_select("Category")
      expect(page).to have_content("All Categories")
    end
  end

  describe "Results display" do
    it "shows product count information" do
      expect(page).to have_content("Showing")
      expect(page).to have_content("products")
    end

    it "updates product count after filtering" do
      select "Electronics", from: "Category"
      click_button "Filter"

      expect(page).to have_content("Showing 1-2 of 2 products")
    end
  end

  describe "Star rating display" do
    it "displays star ratings horizontally" do
      within first('.product-card') do
        stars_container = find('.rating-stars')
        expect(stars_container[:class]).to include('flex')
        expect(stars_container[:class]).to include('items-center')
      end
    end

    it "shows outlined stars for empty ratings" do
      within first('.product-card') do
        stars = all('.rating-star-empty')
        expect(stars.count).to eq(5)

        # Check that stars are outline-only (not filled)
        stars.each do |star|
          expect(star[:fill]).to eq("none")
          expect(star[:stroke]).to eq("currentColor")
        end
      end
    end

    it "displays rating count" do
      within first('.product-card') do
        expect(page).to have_content("(0)")
      end
    end
  end
end
