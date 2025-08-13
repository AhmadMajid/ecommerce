require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#current_user_review_for' do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let!(:product) { create(:product) }
    let!(:user_review) { create(:review, user: user, product: product, rating: 5, title: 'Great!', content: 'Love it!') }
    let!(:other_review) { create(:review, user: other_user, product: product, rating: 3, title: 'OK', content: 'It\'s fine') }

    before do
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns the current user\'s review for the product' do
      expect(helper.current_user_review_for(product)).to eq(user_review)
    end

    it 'does not return other users\' reviews' do
      expect(helper.current_user_review_for(product)).not_to eq(other_review)
    end

    it 'returns nil when user is not signed in' do
      allow(helper).to receive(:user_signed_in?).and_return(false)
      expect(helper.current_user_review_for(product)).to be_nil
    end

    it 'returns nil when user has no review for the product' do
      different_product = create(:product)
      expect(helper.current_user_review_for(different_product)).to be_nil
    end

    it 'caches the result for performance' do
      # First call
      result1 = helper.current_user_review_for(product)

      # Second call should use cached value
      expect(user).not_to receive(:reviews)
      result2 = helper.current_user_review_for(product)

      expect(result1).to eq(result2)
      expect(result1).to eq(user_review)
    end
  end

  describe '#hierarchical_category_options' do
    let!(:electronics) { create(:category, name: "Electronics", position: 1) }
    let!(:clothing) { create(:category, name: "Clothing", position: 2) }
    let!(:smartphones) { create(:category, name: "Smartphones", parent: electronics, position: 1) }
    let!(:laptops) { create(:category, name: "Laptops", parent: electronics, position: 2) }
    let!(:mens_clothing) { create(:category, name: "Men's Clothing", parent: clothing, position: 1) }
    let!(:inactive_category) { create(:category, name: "Inactive", active: false) }

    it 'returns hierarchical options with Unicode tree characters' do
      options = helper.hierarchical_category_options

      expect(options).to include(
        ["Electronics", electronics.id],
        ["├── Laptops", laptops.id],
        ["├── Smartphones", smartphones.id],
        ["Clothing", clothing.id],
        ["├── Men's Clothing", mens_clothing.id]
      )
    end

    it 'excludes inactive categories' do
      options = helper.hierarchical_category_options

      expect(options.map(&:first)).not_to include("Inactive")
    end

    it 'orders categories by position and name' do
      options = helper.hierarchical_category_options

      electronics_index = options.find_index { |opt| opt[0] == "Electronics" }
      clothing_index = options.find_index { |opt| opt[0] == "Clothing" }

      expect(electronics_index).to be < clothing_index
    end

    it 'handles deep nesting' do
      # Create a third level category
      sub_subcategory = create(:category, name: "iPhone Cases", parent: smartphones, position: 1)

      options = helper.hierarchical_category_options

      expect(options).to include(["│   ├── iPhone Cases", sub_subcategory.id])
    end

    it 'can accept custom categories and level' do
      custom_categories = [smartphones, laptops]
      options = helper.hierarchical_category_options(custom_categories, 1)

      expect(options).to include(
        ["├── Laptops", laptops.id],
        ["├── Smartphones", smartphones.id]
      )
    end
  end

  describe '#simple_hierarchical_category_options' do
    let!(:electronics) { create(:category, name: "Electronics", position: 1) }
    let!(:clothing) { create(:category, name: "Clothing", position: 2) }
    let!(:smartphones) { create(:category, name: "Smartphones", parent: electronics, position: 1) }
    let!(:laptops) { create(:category, name: "Laptops", parent: electronics, position: 2) }
    let!(:mens_clothing) { create(:category, name: "Men's Clothing", parent: clothing, position: 1) }

    it 'returns hierarchical options with simple indentation' do
      options = helper.simple_hierarchical_category_options

      expect(options).to include(
        ["Electronics", electronics.id],
        ["  └─ Laptops", laptops.id],
        ["  └─ Smartphones", smartphones.id],
        ["Clothing", clothing.id],
        ["  └─ Men's Clothing", mens_clothing.id]
      )
    end

    it 'handles multiple levels of nesting' do
      # Create a third level category
      sub_subcategory = create(:category, name: "iPhone Cases", parent: smartphones, position: 1)

      options = helper.simple_hierarchical_category_options

      expect(options).to include(
        ["Electronics", electronics.id],
        ["  └─ Smartphones", smartphones.id],
        ["    └─ iPhone Cases", sub_subcategory.id],
        ["  └─ Laptops", laptops.id]
      )
    end

    it 'returns empty array when no categories exist' do
      Category.destroy_all

      options = helper.simple_hierarchical_category_options

      expect(options).to be_empty
    end

    it 'only includes active categories and their active children' do
      inactive_parent = create(:category, name: "Inactive Parent", active: false)
      inactive_child = create(:category, name: "Inactive Child", parent: electronics, active: false)

      options = helper.simple_hierarchical_category_options

      expect(options.map(&:first)).not_to include("Inactive Parent", "Inactive Child")
    end

    it 'preserves order by position then name' do
      # Update positions to test ordering
      clothing.update!(position: 0)
      electronics.update!(position: 1)

      options = helper.simple_hierarchical_category_options

      clothing_index = options.find_index { |opt| opt[0] == "Clothing" }
      electronics_index = options.find_index { |opt| opt[0] == "Electronics" }

      expect(clothing_index).to be < electronics_index
    end
  end
end
