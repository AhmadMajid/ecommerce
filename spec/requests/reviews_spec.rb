require 'rails_helper'

RSpec.describe 'Reviews API', type: :request do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:product) { create(:product) }

  before do
    sign_in user
  end

  describe 'GET /products/:product_slug/reviews/new' do
    it 'returns a successful response' do
      get new_product_review_path(product)
      expect(response).to be_successful
      expect(response.body).to include('Write a Review')
    end
  end

  describe 'POST /products/:product_slug/reviews' do
    let(:valid_review_params) do
      {
        review: {
          rating: 5,
          title: 'Great product!',
          content: 'I really enjoyed using this product. Highly recommended!'
        }
      }
    end

    let(:invalid_review_params) do
      {
        review: {
          rating: nil,
          title: '',
          content: ''
        }
      }
    end

    it 'creates a new review with valid parameters' do
      expect {
        post product_reviews_path(product), params: valid_review_params
      }.to change(Review, :count).by(1)

      expect(response).to redirect_to(product)
      follow_redirect!
      expect(response.body).to include('Thank you for your review!')

      review = Review.last
      expect(review.user).to eq(user)
      expect(review.product).to eq(product)
    end

    it 'does not create review with invalid parameters' do
      expect {
        post product_reviews_path(product), params: invalid_review_params
      }.not_to change(Review, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'prevents duplicate reviews' do
      create(:review, user: user, product: product, rating: 4, title: 'Previous', content: 'Previous review')

      expect {
        post product_reviews_path(product), params: valid_review_params
      }.not_to change(Review, :count)

      expect(response).to redirect_to(product)
      follow_redirect!
      expect(response.body).to include('You have already reviewed this product')
    end
  end

  describe 'GET /products/:product_slug/reviews/:id/edit' do
    let!(:review) { create(:review, user: user, product: product, rating: 4, title: 'My review', content: 'My thoughts') }

    it 'returns a successful response for own review' do
      get edit_product_review_path(product, review)
      expect(response).to be_successful
      expect(response.body).to include('Edit Your Review')
    end

    it 'redirects when trying to edit another user\'s review' do
      other_review = create(:review, user: other_user, product: product, rating: 3, title: 'Other', content: 'Other thoughts')

      get edit_product_review_path(product, other_review)
      expect(response).to redirect_to(product)
      follow_redirect!
      expect(response.body).to include('You can only edit your own reviews')
    end
  end

  describe 'PATCH /products/:product_slug/reviews/:id' do
    let!(:review) { create(:review, user: user, product: product, rating: 4, title: 'Old title', content: 'Old content') }

    let(:valid_update_params) do
      {
        review: {
          rating: 5,
          title: 'Updated title',
          content: 'Updated content with more details'
        }
      }
    end

    it 'updates the review with valid parameters' do
      patch product_review_path(product, review), params: valid_update_params

      review.reload
      expect(review.rating).to eq(5)
      expect(review.title).to eq('Updated title')
      expect(review.content).to eq('Updated content with more details')

      expect(response).to redirect_to(product)
      follow_redirect!
      expect(response.body).to include('Your review has been updated!')
    end

    it 'prevents updating another user\'s review' do
      other_review = create(:review, user: other_user, product: product, rating: 3, title: 'Other', content: 'Other')

      patch product_review_path(product, other_review), params: valid_update_params

      expect(response).to redirect_to(product)
      follow_redirect!
      expect(response.body).to include('You can only edit your own reviews')
    end
  end

  describe 'DELETE /products/:product_slug/reviews/:id' do
    let!(:review) { create(:review, user: user, product: product, rating: 4, title: 'My review', content: 'My thoughts') }

    it 'deletes the review' do
      expect {
        delete product_review_path(product, review)
      }.to change(Review, :count).by(-1)

      expect(response).to redirect_to(product)
      follow_redirect!
      expect(response.body).to include('Your review has been deleted')
    end

    it 'prevents deleting another user\'s review' do
      other_review = create(:review, user: other_user, product: product, rating: 3, title: 'Other', content: 'Other')

      expect {
        delete product_review_path(product, other_review)
      }.not_to change(Review, :count)

      expect(response).to redirect_to(product)
      follow_redirect!
      expect(response.body).to include('You can only edit your own reviews')
    end
  end

  describe 'authentication' do
    before { sign_out user }

    it 'redirects to login when not authenticated' do
      get new_product_review_path(product)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for create when not authenticated' do
      post product_reviews_path(product), params: {
        review: { rating: 5, title: 'Test', content: 'Test content' }
      }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
