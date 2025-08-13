require 'rails_helper'

RSpec.describe Wishlist, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:product) }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:product) { create(:product) }

    it 'validates uniqueness of user_id scoped to product_id' do
      create(:wishlist, user: user, product: product)
      duplicate_wishlist = build(:wishlist, user: user, product: product)

      expect(duplicate_wishlist).not_to be_valid
      expect(duplicate_wishlist.errors[:user_id]).to be_present
    end

    it 'allows different users to wishlist the same product' do
      another_user = create(:user)
      create(:wishlist, user: user, product: product)
      different_user_wishlist = build(:wishlist, user: another_user, product: product)

      expect(different_user_wishlist).to be_valid
    end

    it 'allows same user to wishlist different products' do
      another_product = create(:product)
      create(:wishlist, user: user, product: product)
      different_product_wishlist = build(:wishlist, user: user, product: another_product)

      expect(different_product_wishlist).to be_valid
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      user = create(:user)
      product = create(:product)
      wishlist = create(:wishlist, user: user, product: product)

      expect(wishlist).to be_valid
      expect(wishlist.user).to eq(user)
      expect(wishlist.product).to eq(product)
    end
  end
end
