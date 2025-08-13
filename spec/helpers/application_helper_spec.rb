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
end
