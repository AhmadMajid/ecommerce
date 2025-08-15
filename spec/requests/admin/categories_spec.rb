require 'rails_helper'

RSpec.describe 'Admin Categories', type: :request do
  let(:admin_user) { create(:user, role: 'admin') }
  let(:category) { create(:category) }
  let(:parent_category) { create(:category, name: 'Parent Category') }

  before do
    sign_in admin_user
  end

  describe 'GET /admin/categories' do
    before do
      category
      parent_category
    end

    it 'returns successful response' do
      get admin_categories_path
      expect(response).to have_http_status(:success)
    end

    it 'displays categories' do
      get admin_categories_path
      expect(response.body).to include(category.name)
      expect(response.body).to include(parent_category.name)
    end

    context 'with search parameter' do
      it 'filters categories by name' do
        get admin_categories_path, params: { search: 'Parent' }
        expect(response.body).to include(parent_category.name)
        expect(response.body).not_to include(category.name)
      end
    end

    context 'with parent_id parameter' do
      let!(:child_category) { create(:category, parent: parent_category) }

      it 'filters by parent category' do
        get admin_categories_path, params: { parent_id: parent_category.id }
        expect(response.body).to include(child_category.name)
      end

      it 'filters root categories when parent_id is "root"' do
        get admin_categories_path, params: { parent_id: 'root' }
        expect(response.body).to include(category.name)
        expect(response.body).to include(parent_category.name)
      end
    end

    context 'with status parameter' do
      let!(:inactive_category) { create(:category, active: false) }

      it 'filters active categories' do
        get admin_categories_path, params: { status: 'active' }
        expect(response.body).not_to include(inactive_category.name)
      end

      it 'filters inactive categories' do
        get admin_categories_path, params: { status: 'inactive' }
        expect(response.body).to include(inactive_category.name)
      end
    end
  end

  describe 'GET /admin/categories/:id' do
    let!(:product) { create(:product, category: category) }

    it 'returns successful response' do
      get admin_category_path(category)
      expect(response).to have_http_status(:success)
    end

    it 'displays category details' do
      get admin_category_path(category)
      expect(response.body).to include(category.name)
      expect(response.body).to include(category.description) if category.description.present?
    end

    it 'displays products in category' do
      get admin_category_path(category)
      expect(response.body).to include(product.name)
    end

    it 'displays category stats' do
      get admin_category_path(category)
      expect(response.body).to include('Total Products')
      expect(response.body).to include('1') # one product
    end
  end

  describe 'GET /admin/categories/new' do
    it 'returns successful response' do
      get new_admin_category_path
      expect(response).to have_http_status(:success)
    end

    it 'displays form fields' do
      get new_admin_category_path
      expect(response.body).to include('name="category[name]"')
      expect(response.body).to include('name="category[description]"')
      expect(response.body).to include('name="category[sort_order]"')
    end
  end

  describe 'POST /admin/categories' do
    let(:valid_attributes) do
      {
        name: 'Test Category',
        description: 'Test description',
        sort_order: 1
      }
    end

    it 'creates a new category' do
      expect {
        post admin_categories_path, params: { category: valid_attributes }
      }.to change(Category, :count).by(1)
    end

    it 'redirects to the created category' do
      post admin_categories_path, params: { category: valid_attributes }
      expect(response).to redirect_to(admin_category_path(Category.last))
    end

    it 'sets position automatically' do
      post admin_categories_path, params: { category: valid_attributes }
      created_category = Category.last
      expect(created_category.position).to be_present
    end

    context 'with invalid attributes' do
      it 'returns unprocessable entity status' do
        post admin_categories_path, params: { category: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /admin/categories/:id/edit' do
    it 'returns successful response' do
      get edit_admin_category_path(category)
      expect(response).to have_http_status(:success)
    end

    it 'displays pre-filled form' do
      get edit_admin_category_path(category)
      expect(response.body).to include(category.name)
    end
  end

  describe 'PATCH /admin/categories/:id' do
    let(:update_attributes) do
      {
        name: 'Updated Category',
        description: 'Updated description'
      }
    end

    it 'updates the category' do
      patch admin_category_path(category), params: { category: update_attributes }
      category.reload
      expect(category.name).to eq('Updated Category')
      expect(category.description).to eq('Updated description')
    end

    it 'redirects to the category' do
      patch admin_category_path(category), params: { category: update_attributes }
      expect(response).to redirect_to(admin_category_path(category))
    end
  end

  describe 'DELETE /admin/categories/:id' do
    it 'deletes the category when possible' do
      category_to_delete = create(:category)
      expect {
        delete admin_category_path(category_to_delete)
      }.to change(Category, :count).by(-1)
    end

    it 'redirects to categories index' do
      delete admin_category_path(category)
      expect(response).to redirect_to(admin_categories_path)
    end
  end
end
