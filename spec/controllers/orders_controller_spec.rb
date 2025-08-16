require 'rails_helper'

RSpec.describe OrdersController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:order) { create(:order, user: user) }

  before do
    sign_in user
  end

  describe 'GET /orders' do
    let!(:user_orders) { create_list(:order, 3, user: user) }
    let!(:other_user_orders) { create_list(:order, 2, user: other_user) }

    it 'returns user orders only' do
      get orders_path
      expect(response).to have_http_status(:success)
      expect(assigns(:orders).count).to eq(3)
      expect(assigns(:orders)).to include(*user_orders)
      expect(assigns(:orders)).not_to include(*other_user_orders)
    end

    it 'orders by most recent first' do
      newest_order = create(:order, user: user, created_at: 1.day.from_now)
      
      get orders_path
      expect(assigns(:orders).first).to eq(newest_order)
    end

    context 'when not signed in' do
      before { sign_out user }

      it 'redirects to sign in' do
        get orders_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /orders/:id' do
    context 'with own order' do
      it 'shows the order' do
        get order_path(order)
        expect(response).to have_http_status(:success)
        expect(assigns(:order)).to eq(order)
      end
    end

    context 'with another user\'s order' do
      let(:other_order) { create(:order, user: other_user) }

      it 'redirects with error message' do
        get order_path(other_order)
        expect(response).to redirect_to(orders_path)
        expect(flash[:alert]).to eq('Order not found.')
      end
    end

    context 'with non-existent order' do
      it 'redirects with error message' do
        get order_path(id: 99999)
        expect(response).to redirect_to(orders_path)
        expect(flash[:alert]).to eq('Order not found.')
      end
    end

    context 'when not signed in' do
      before { sign_out user }

      it 'redirects to sign in' do
        get order_path(order)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
