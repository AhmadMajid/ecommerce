require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:wishlists).dependent(:destroy) }
    it { should have_many(:wishlist_products).through(:wishlists).source(:product) }
    it { should have_many(:reviews).dependent(:destroy) }
  end

  describe 'wishlist functionality' do
    let!(:user) { create(:user) }
    let!(:product1) { create(:product) }
    let!(:product2) { create(:product) }

    it 'can have multiple wishlist items' do
      user.wishlists.create!(product: product1)
      user.wishlists.create!(product: product2)

      expect(user.wishlists.count).to eq(2)
      expect(user.wishlist_products).to include(product1, product2)
    end

    it 'destroys wishlists when user is destroyed' do
      user.wishlists.create!(product: product1)
      user.wishlists.create!(product: product2)

      expect { user.destroy }.to change(Wishlist, :count).by(-2)
    end
  end

  describe 'review functionality' do
    let!(:user) { create(:user) }
    let!(:product1) { create(:product) }
    let!(:product2) { create(:product) }

    it 'can have multiple reviews' do
      user.reviews.create!(product: product1, rating: 5, title: 'Great!', content: 'Love it!')
      user.reviews.create!(product: product2, rating: 4, title: 'Good', content: 'Nice product')

      expect(user.reviews.count).to eq(2)
    end

    it 'destroys reviews when user is destroyed' do
      user.reviews.create!(product: product1, rating: 5, title: 'Great!', content: 'Love it!')
      user.reviews.create!(product: product2, rating: 4, title: 'Good', content: 'Nice product')

      expect { user.destroy }.to change(Review, :count).by(-2)
    end

    it 'cannot create duplicate reviews for the same product' do
      user.reviews.create!(product: product1, rating: 5, title: 'Great!', content: 'Love it!')

      duplicate_review = user.reviews.build(product: product1, rating: 4, title: 'Different', content: 'Different content')
      expect(duplicate_review).not_to be_valid
      expect(duplicate_review.errors[:user_id]).to include('can only review a product once')
    end
  end
end
