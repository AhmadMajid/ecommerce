require 'rails_helper'

RSpec.describe Admin::CategoriesController, type: :controller do
  let(:admin_user) { create(:user, role: :admin) }
  let(:category) { create(:category) }
  let(:parent_category) { create(:category, name: 'Parent Category') }
  let(:child_category) { create(:category, name: 'Child Category', parent: parent_category) }

  before do
    sign_in admin_user
  end

  # Helper method to simulate admin authentication
  def authenticate_admin
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(admin_user)
    allow(controller).to receive(:ensure_admin).and_return(true)
  end

  before(:each) do
    authenticate_admin
  end

  describe 'GET #index' do
    before do
      category
      parent_category
      child_category
    end

    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns @categories' do
      get :index
      expect(assigns(:categories).count).to eq(3)
    end

    context 'with search parameter' do
      it 'filters categories by name' do
        get :index, params: { search: 'Parent' }
        expect(assigns(:categories)).to include(parent_category)
        expect(assigns(:categories)).not_to include(child_category)
      end
    end

    context 'with parent_id parameter' do
      it 'filters by parent category' do
        get :index, params: { parent_id: parent_category.id }
        expect(assigns(:categories)).to include(child_category)
        expect(assigns(:categories)).not_to include(parent_category)
      end

      it 'filters root categories when parent_id is "root"' do
        get :index, params: { parent_id: 'root' }
        expect(assigns(:categories)).to include(category)
        expect(assigns(:categories)).to include(parent_category)
        expect(assigns(:categories)).not_to include(child_category)
      end
    end

    context 'with status parameter' do
      let!(:inactive_category) { create(:category, active: false) }
      let!(:featured_category) { create(:category, featured: true) }

      it 'filters active categories' do
        get :index, params: { status: 'active' }
        expect(assigns(:categories)).not_to include(inactive_category)
      end

      it 'filters inactive categories' do
        get :index, params: { status: 'inactive' }
        expect(assigns(:categories)).to include(inactive_category)
      end

      it 'filters featured categories' do
        get :index, params: { status: 'featured' }
        expect(assigns(:categories)).to include(featured_category)
      end
    end
  end

  describe 'GET #show' do
    let!(:product) { create(:product, category: category) }

    it 'returns a successful response' do
      get :show, params: { id: category.slug }
      expect(response).to be_successful
    end

    it 'assigns the requested category' do
      get :show, params: { id: category.slug }
      expect(assigns(:category)).to eq(category)
    end

    it 'assigns products in the category' do
      get :show, params: { id: category.slug }
      expect(assigns(:products)).to include(product)
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new category' do
      get :new
      expect(assigns(:category)).to be_a_new(Category)
    end

    it 'assigns parent categories' do
      parent_category
      get :new
      expect(assigns(:parent_categories)).to include(parent_category)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        name: 'Test Category',
        description: 'Test description',
        sort_order: 1
      }
    end

    let(:invalid_attributes) do
      {
        name: ''
      }
    end

    context 'with valid parameters' do
      it 'creates a new Category' do
        expect {
          post :create, params: { category: valid_attributes }
        }.to change(Category, :count).by(1)
      end

      it 'redirects to the created category' do
        post :create, params: { category: valid_attributes }
        expect(response).to redirect_to(admin_category_path(Category.last))
      end

      it 'sets position automatically' do
        post :create, params: { category: valid_attributes }
        expect(Category.last.position).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Category' do
        expect {
          post :create, params: { category: invalid_attributes }
        }.to change(Category, :count).by(0)
      end

      it 'renders the new template' do
        post :create, params: { category: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a successful response' do
      get :edit, params: { id: category.slug }
      expect(response).to be_successful
    end

    it 'assigns the requested category' do
      get :edit, params: { id: category.slug }
      expect(assigns(:category)).to eq(category)
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) do
      {
        name: 'Updated Category',
        description: 'Updated description',
        sort_order: 10
      }
    end

    context 'with valid parameters' do
      it 'updates the requested category' do
        patch :update, params: { id: category.slug, category: new_attributes }
        category.reload
        expect(category.name).to eq('Updated Category')
        expect(category.description).to eq('Updated description')
        expect(category.sort_order).to eq(10)
      end

      it 'redirects to the category' do
        patch :update, params: { id: category.slug, category: new_attributes }
        expect(response).to redirect_to(admin_category_path(assigns(:category)))
      end
    end

    context 'with invalid parameters' do
      it 'renders the edit template' do
        patch :update, params: { id: category.slug, category: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested category if it can be deleted' do
      category_to_delete = create(:category)
      expect {
        delete :destroy, params: { id: category_to_delete.slug }
      }.to change(Category, :count).by(-1)
    end

    it 'redirects to the categories list' do
      delete :destroy, params: { id: category.slug }
      expect(response).to redirect_to(admin_categories_path)
    end
  end
end
