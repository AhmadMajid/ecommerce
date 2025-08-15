require 'rails_helper'

RSpec.describe Admin::ProductsController, type: :controller do
  let(:admin_user) { create(:user, role: 'admin') }
  let(:category) { create(:category) }
  let(:product) { create(:product, category: category) }

  before do
    sign_in admin_user
  end

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns @products' do
      product
      get :index
      expect(assigns(:products)).to include(product)
    end
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      get :show, params: { id: product.slug }
      expect(response).to be_successful
    end

    it 'assigns the requested product' do
      get :show, params: { id: product.slug }
      expect(assigns(:product)).to eq(product)
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new product' do
      get :new
      expect(assigns(:product)).to be_a_new(Product)
    end

    it 'assigns categories' do
      category
      get :new
      expect(assigns(:categories)).to include(category)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        name: 'Test Product',
        description: 'Test description',
        sku: 'TEST-001',
        price: 99.99,
        category_id: category.id,
        tags: 'electronics, gadget',
        sort_order: 1
      }
    end

    let(:invalid_attributes) do
      {
        name: '',
        price: nil
      }
    end

    context 'with valid parameters' do
      it 'creates a new Product' do
        expect {
          post :create, params: { product: valid_attributes }
        }.to change(Product, :count).by(1)
      end

      it 'redirects to the created product' do
        post :create, params: { product: valid_attributes }
        expect(response).to redirect_to(admin_product_path(Product.last))
      end

      it 'sets the tag_list properly' do
        post :create, params: { product: valid_attributes }
        expect(Product.last.tag_list).to eq(['electronics', 'gadget'])
      end
    end

    context 'with save_as_draft parameter' do
      it 'creates an inactive product' do
        post :create, params: { product: valid_attributes, save_as_draft: true }
        expect(Product.last.active).to be_falsey
        expect(Product.last.published_at).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Product' do
        expect {
          post :create, params: { product: invalid_attributes }
        }.to change(Product, :count).by(0)
      end

      it 'renders the new template' do
        post :create, params: { product: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a successful response' do
      get :edit, params: { id: product.slug }
      expect(response).to be_successful
    end

    it 'assigns the requested product' do
      get :edit, params: { id: product.slug }
      expect(assigns(:product)).to eq(product)
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) do
      {
        name: 'Updated Product',
        tags: 'updated, tags',
        sort_order: 5
      }
    end

    context 'with valid parameters' do
      it 'updates the requested product' do
        patch :update, params: { id: product.slug, product: new_attributes }
        product.reload
        expect(product.name).to eq('Updated Product')
        expect(product.tag_list).to eq(['updated', 'tags'])
        expect(product.sort_order).to eq(5)
      end

      it 'redirects to the product' do
        patch :update, params: { id: product.slug, product: new_attributes }
        expect(response).to redirect_to(admin_product_path(product))
      end
    end

    context 'with save_as_draft parameter' do
      it 'saves product as draft' do
        patch :update, params: { id: product.slug, product: new_attributes, save_as_draft: true }
        product.reload
        expect(product.active).to be_falsey
        expect(product.published_at).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'renders the edit template' do
        patch :update, params: { id: product.slug, product: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested product if it can be deleted' do
      product_to_delete = create(:product, category: category)
      expect {
        delete :destroy, params: { id: product_to_delete.slug }
      }.to change(Product, :count).by(-1)
    end

    it 'redirects to the products list' do
      delete :destroy, params: { id: product.slug }
      expect(response).to redirect_to(admin_products_path)
    end
  end
end
