require 'rails_helper'

RSpec.describe Review, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:product) }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:product) { create(:product) }

    it { should validate_presence_of(:rating) }
    it { should validate_inclusion_of(:rating).in_range(1..5) }
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(100) }
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(1000) }

    it 'validates uniqueness of user_id scoped to product_id' do
      create(:review, user: user, product: product, rating: 5, title: 'Great!', content: 'Love it!')
      duplicate_review = build(:review, user: user, product: product, rating: 4, title: 'Good', content: 'Nice')

      expect(duplicate_review).not_to be_valid
      expect(duplicate_review.errors[:user_id]).to include('can only review a product once')
    end

    it 'allows different users to review the same product' do
      another_user = create(:user)
      create(:review, user: user, product: product, rating: 5, title: 'Great!', content: 'Love it!')
      different_user_review = build(:review, user: another_user, product: product, rating: 4, title: 'Good', content: 'Nice')

      expect(different_user_review).to be_valid
    end

    it 'allows same user to review different products' do
      another_product = create(:product)
      create(:review, user: user, product: product, rating: 5, title: 'Great!', content: 'Love it!')
      different_product_review = build(:review, user: user, product: another_product, rating: 4, title: 'Good', content: 'Nice')

      expect(different_product_review).to be_valid
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      user = create(:user)
      product = create(:product)
      review = create(:review, user: user, product: product, rating: 5, title: 'Excellent!', content: 'This product exceeded my expectations!')

      expect(review).to be_valid
      expect(review.user).to eq(user)
      expect(review.product).to eq(product)
      expect(review.rating).to eq(5)
      expect(review.title).to eq('Excellent!')
      expect(review.content).to eq('This product exceeded my expectations!')
    end
  end

  describe 'rating boundaries' do
    let(:user) { create(:user) }
    let(:product) { create(:product) }

    it 'accepts valid ratings from 1 to 5' do
      (1..5).each do |rating|
        review = build(:review, user: user, product: product, rating: rating, title: 'Test', content: 'Test content')
        expect(review).to be_valid
      end
    end

    it 'rejects ratings outside 1-5 range' do
      [0, 6, -1, 10].each do |invalid_rating|
        review = build(:review, user: user, product: product, rating: invalid_rating, title: 'Test', content: 'Test content')
        expect(review).not_to be_valid
        expect(review.errors[:rating]).to be_present
      end
    end
  end
end
