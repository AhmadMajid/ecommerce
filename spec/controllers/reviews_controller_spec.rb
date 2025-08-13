require 'rails_helper'

RSpec.describe ReviewsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:product) { create(:product) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new, params: { product_slug: product.slug }
      expect(response).to be_successful
    end

    it 'assigns a new review to @review' do
      get :new, params: { product_slug: product.slug }
      expect(assigns(:review)).to be_a_new(Review)
      expect(assigns(:review).product).to eq(product)
    end

    it 'assigns the product to @product' do
      get :new, params: { product_slug: product.slug }
      expect(assigns(:product)).to eq(product)
    end
  end

  describe 'POST #create' do
    let(:valid_review_params) do
      {
        product_slug: product.slug,
        review: {
          rating: 5,
          title: 'Great product!',
          content: 'I really enjoyed using this product. Highly recommended!'
        }
      }
    end

    let(:invalid_review_params) do
      {
        product_slug: product.slug,
        review: {
          rating: nil,
          title: '',
          content: ''
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new review' do
        expect {
          post :create, params: valid_review_params
        }.to change(Review, :count).by(1)
      end

      it 'assigns the review to the current user' do
        post :create, params: valid_review_params
        expect(Review.last.user).to eq(user)
      end

      it 'assigns the review to the correct product' do
        post :create, params: valid_review_params
        expect(Review.last.product).to eq(product)
      end

      it 'redirects to the product with success notice' do
        post :create, params: valid_review_params
        expect(response).to redirect_to(product)
        expect(flash[:notice]).to eq('Thank you for your review!')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a review' do
        expect {
          post :create, params: invalid_review_params
        }.not_to change(Review, :count)
      end

      it 'renders the new template with errors' do
        post :create, params: invalid_review_params
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when user already has a review for the product' do
      before do
        create(:review, user: user, product: product, rating: 4, title: 'Previous review', content: 'My previous thoughts')
      end

      it 'redirects with alert message' do
        post :create, params: valid_review_params
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to eq('You have already reviewed this product.')
      end

      it 'does not create a duplicate review' do
        expect {
          post :create, params: valid_review_params
        }.not_to change(Review, :count)
      end
    end
  end

  describe 'GET #edit' do
    let!(:review) { create(:review, user: user, product: product, rating: 4, title: 'My review', content: 'My thoughts') }

    it 'returns a successful response' do
      get :edit, params: { product_slug: product.slug, id: review.id }
      expect(response).to be_successful
    end

    it 'assigns the review to @review' do
      get :edit, params: { product_slug: product.slug, id: review.id }
      expect(assigns(:review)).to eq(review)
    end

    context 'when trying to edit another user\'s review' do
      let!(:other_review) { create(:review, user: other_user, product: product, rating: 3, title: 'Other review', content: 'Other thoughts') }

      it 'redirects with alert message' do
        get :edit, params: { product_slug: product.slug, id: other_review.id }
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to eq('You can only edit your own reviews.')
      end
    end
  end

  describe 'PATCH #update' do
    let!(:review) { create(:review, user: user, product: product, rating: 4, title: 'Old title', content: 'Old content') }

    let(:valid_update_params) do
      {
        product_slug: product.slug,
        id: review.id,
        review: {
          rating: 5,
          title: 'Updated title',
          content: 'Updated content with more details'
        }
      }
    end

    let(:invalid_update_params) do
      {
        product_slug: product.slug,
        id: review.id,
        review: {
          rating: nil,
          title: '',
          content: ''
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the review' do
        patch :update, params: valid_update_params
        review.reload
        expect(review.rating).to eq(5)
        expect(review.title).to eq('Updated title')
        expect(review.content).to eq('Updated content with more details')
      end

      it 'redirects to the product with success notice' do
        patch :update, params: valid_update_params
        expect(response).to redirect_to(product)
        expect(flash[:notice]).to eq('Your review has been updated!')
      end
    end

    context 'with invalid parameters' do
      it 'does not update the review' do
        original_title = review.title
        patch :update, params: invalid_update_params
        review.reload
        expect(review.title).to eq(original_title)
      end

      it 'renders the edit template with errors' do
        patch :update, params: invalid_update_params
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when trying to update another user\'s review' do
      let!(:other_review) { create(:review, user: other_user, product: product, rating: 3, title: 'Other title', content: 'Other content') }

      it 'redirects with alert message' do
        patch :update, params: {
          product_slug: product.slug,
          id: other_review.id,
          review: { rating: 5, title: 'Hacked title', content: 'Hacked content' }
        }
        expect(response).to redirect_to(product)
        expect(flash[:alert]).to eq('You can only edit your own reviews.')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:review) { create(:review, user: user, product: product, rating: 4, title: 'My review', content: 'My thoughts') }

    it 'deletes the review' do
      expect {
        delete :destroy, params: { product_slug: product.slug, id: review.id }
      }.to change(Review, :count).by(-1)
    end

    it 'redirects to the product with success notice' do
      delete :destroy, params: { product_slug: product.slug, id: review.id }
      expect(response).to redirect_to(product)
      expect(flash[:notice]).to eq('Your review has been deleted.')
    end

    context 'when trying to delete another user\'s review' do
      let!(:other_review) { create(:review, user: other_user, product: product, rating: 3, title: 'Other review', content: 'Other thoughts') }

      it 'redirects with alert message and does not delete' do
        expect {
          delete :destroy, params: { product_slug: product.slug, id: other_review.id }
        }.not_to change(Review, :count)

        expect(response).to redirect_to(product)
        expect(flash[:alert]).to eq('You can only edit your own reviews.')
      end
    end
  end

  describe 'authentication' do
    before do
      sign_out user
    end

    it 'redirects to login for new when not authenticated' do
      get :new, params: { product_slug: product.slug }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for create when not authenticated' do
      post :create, params: {
        product_slug: product.slug,
        review: { rating: 5, title: 'Test', content: 'Test content' }
      }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'product finding' do
    it 'raises RecordNotFound for invalid product slug' do
      expect {
        get :new, params: { product_slug: 'invalid-slug' }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
