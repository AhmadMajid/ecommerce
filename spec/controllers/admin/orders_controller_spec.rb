require 'rails_helper'

RSpec.describe Admin::OrdersController, type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:customer_user) { create(:user) }
  let(:order) { create(:order, user: customer_user) }

  before do
    sign_in admin_user
  end

  describe 'GET /admin/orders' do
    let!(:orders) { create_list(:order, 5, user: customer_user) }

    it 'lists all orders' do
      get admin_orders_path
      expect(response).to have_http_status(:success)
      expect(assigns(:orders).count).to eq(5)
    end

    it 'filters by status' do
      confirmed_order = create(:order, user: customer_user, status: :confirmed)
      pending_order = create(:order, user: customer_user, status: :pending)

      get admin_orders_path, params: { status: 'confirmed' }
      expect(response).to have_http_status(:success)
      expect(assigns(:orders)).to include(confirmed_order)
      expect(assigns(:orders)).not_to include(pending_order)
    end

    context 'when not admin' do
      before do
        sign_out admin_user
        sign_in customer_user
      end

      it 'redirects to unauthorized' do
        get admin_orders_path
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when not signed in' do
      before { sign_out admin_user }

      it 'redirects to sign in' do
        get admin_orders_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin/orders/:id' do
    it 'shows order details' do
      get admin_order_path(order)
      expect(response).to have_http_status(:success)
      expect(assigns(:order)).to eq(order)
    end

    context 'with Stripe payment intent' do
      before do
        order.update!(stripe_payment_intent_id: 'pi_test123')
        payment_intent = double('Stripe::PaymentIntent', id: 'pi_test123')
        allow(order).to receive(:payment_intent).and_return(payment_intent)
      end

      it 'loads payment intent' do
        get admin_order_path(order)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /admin/orders/:id/edit' do
    it 'shows edit form' do
      get edit_admin_order_path(order)
      expect(response).to have_http_status(:success)
      expect(assigns(:order)).to eq(order)
    end
  end

  describe 'PATCH /admin/orders/:id' do
    let(:update_params) do
      {
        order: {
          status: 'processing',
          notes: 'Processing order'
        }
      }
    end

    it 'updates order successfully' do
      patch admin_order_path(order), params: update_params
      expect(response).to redirect_to(admin_order_path(order))
      expect(flash[:notice]).to eq('Order updated successfully.')
      
      order.reload
      expect(order.status).to eq('processing')
      expect(order.notes).to eq('Processing order')
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          order: {
            status: 'invalid_status'
          }
        }
      end

      it 'renders edit with errors' do
        patch admin_order_path(order), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH /admin/orders/:id/cancel' do
    context 'when order can be cancelled' do
      let(:cancellable_order) { create(:order, user: customer_user, status: :pending) }

      it 'cancels the order' do
        patch cancel_admin_order_path(cancellable_order)
        expect(response).to redirect_to(admin_order_path(cancellable_order))
        expect(flash[:notice]).to eq('Order cancelled successfully.')
        
        cancellable_order.reload
        expect(cancellable_order.status).to eq('cancelled')
      end
    end

    context 'when order cannot be cancelled' do
      let(:shipped_order) { create(:order, user: customer_user, status: :shipped) }

      it 'redirects with error' do
        patch cancel_admin_order_path(shipped_order)
        expect(response).to redirect_to(admin_order_path(shipped_order))
        expect(flash[:alert]).to eq('Order cannot be cancelled.')
      end
    end
  end

  describe 'PATCH /admin/orders/:id/refund' do
    before do
      order.update!(
        stripe_payment_intent_id: 'pi_test123',
        payment_status: :paid,
        status: :confirmed
      )
    end

    context 'with successful refund' do
      before do
        allow(PaymentService).to receive(:refund_payment).and_return(true)
      end

      it 'processes full refund' do
        patch refund_admin_order_path(order)
        expect(response).to redirect_to(admin_order_path(order))
        expect(flash[:notice]).to eq('Refund processed successfully.')
        expect(PaymentService).to have_received(:refund_payment).with(order, nil)
      end

      it 'processes partial refund' do
        patch refund_admin_order_path(order), params: { refund_amount: '25.00' }
        expect(response).to redirect_to(admin_order_path(order))
        expect(PaymentService).to have_received(:refund_payment).with(order, 25.00)
      end
    end

    context 'with failed refund' do
      before do
        allow(PaymentService).to receive(:refund_payment).and_return(false)
      end

      it 'redirects with error message' do
        patch refund_admin_order_path(order)
        expect(response).to redirect_to(admin_order_path(order))
        expect(flash[:alert]).to eq('Refund failed. Please try again.')
      end
    end
  end
end
