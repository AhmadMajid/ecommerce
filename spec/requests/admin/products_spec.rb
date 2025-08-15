require 'rails_helper'

RSpec.describe 'Admin Products', type: :request do
  let(:admin_user) { create(:user, role: :admin) }
  let(:category) { create(:category) }
  let(:product) { create(:product, category: category) }

  before do
    sign_in admin_user
  end

  describe 'GET /admin/products' do
    it 'returns successful response' do
      get admin_products_path
      expect(response).to have_http_status(:success)
    end

    it 'displays products' do
      product
      get admin_products_path
      expect(response.body).to include(product.name)
    end
  end

  describe 'GET /admin/products/:id' do
    it 'returns successful response' do
      get admin_product_path(product)
      expect(response).to have_http_status(:success)
    end

    it 'displays product details' do
      get admin_product_path(product)
      expect(response.body).to include(product.name)
      expect(response.body).to include(product.sku)
      expect(response.body).to include("$#{product.price}")
    end

    it 'displays tags if present' do
      product.update(tags: 'electronics, gadget')
      get admin_product_path(product)
      expect(response.body).to include('electronics')
      expect(response.body).to include('gadget')
    end
  end

  describe 'GET /admin/products/new' do
    it 'returns successful response' do
      get new_admin_product_path
      expect(response).to have_http_status(:success)
    end

    it 'displays form fields' do
      get new_admin_product_path
      expect(response.body).to include('name="product[name]"')
      expect(response.body).to include('name="product[sku]"')
      expect(response.body).to include('name="product[price]"')
      expect(response.body).to include('name="product[tags]"')
    end
  end

  describe 'POST /admin/products' do
    let(:valid_attributes) do
      {
        name: 'Test Product',
        description: 'Test description',
        sku: 'TEST-001',
        price: 99.99,
        category_id: category.id,
        tags: 'electronics, gadget'
      }
    end

    it 'creates a new product' do
      expect {
        post admin_products_path, params: { product: valid_attributes }
      }.to change(Product, :count).by(1)
    end

    it 'redirects to the created product' do
      post admin_products_path, params: { product: valid_attributes }
      expect(response).to redirect_to(admin_product_path(Product.last))
    end

    it 'processes tags correctly' do
      post admin_products_path, params: { product: valid_attributes }
      created_product = Product.last
      expect(created_product.tag_list).to eq(['electronics', 'gadget'])
    end

    context 'with save_as_draft' do
      it 'creates inactive product' do
        post admin_products_path, params: { product: valid_attributes, save_as_draft: true }
        created_product = Product.last
        expect(created_product.active).to be_falsey
        expect(created_product.published_at).to be_nil
      end
    end

    context 'with invalid attributes' do
      it 'returns unprocessable entity status' do
        post admin_products_path, params: { product: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /admin/products/:id/edit' do
    it 'returns successful response' do
      get edit_admin_product_path(product)
      expect(response).to have_http_status(:success)
    end

    it 'displays pre-filled form' do
      get edit_admin_product_path(product)
      expect(response.body).to include(product.name)
      expect(response.body).to include(product.sku)
    end
  end

  describe 'PATCH /admin/products/:id' do
    let(:update_attributes) do
      {
        name: 'Updated Product',
        tags: 'updated, tags'
      }
    end

    it 'updates the product' do
      patch admin_product_path(product), params: { product: update_attributes }
      product.reload
      expect(product.name).to eq('Updated Product')
      expect(product.tag_list).to eq(['updated', 'tags'])
    end

    it 'redirects to the product' do
      patch admin_product_path(product), params: { product: update_attributes }
      updated_product = Product.find(product.id)
      expect(response).to redirect_to(admin_product_path(updated_product))
    end

    context 'with save_as_draft' do
      it 'saves as draft' do
        patch admin_product_path(product), params: { 
          product: update_attributes, 
          save_as_draft: true 
        }
        product.reload
        expect(product.active).to be_falsey
      end
    end
  end

  describe 'DELETE /admin/products/:id' do
    it 'deletes the product' do
      product_to_delete = create(:product, category: category)
      expect {
        delete admin_product_path(product_to_delete)
      }.to change(Product, :count).by(-1)
    end

    it 'redirects to products index' do
      delete admin_product_path(product)
      expect(response).to redirect_to(admin_products_path)
    end
  end
end
