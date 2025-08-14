require 'rails_helper'

RSpec.describe CartCleanupJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:user) { create(:user) }

    before do
      # Clear any existing carts
      Cart.destroy_all
    end

    describe 'empty guest cart cleanup' do
      it 'deletes empty guest carts older than 1 hour' do
        # Create empty guest cart older than 1 hour
        old_empty_cart = create(:cart, user: nil, session_id: 'guest123', created_at: 2.hours.ago)

        # Create recent empty guest cart (should not be deleted)
        recent_empty_cart = create(:cart, user: nil, session_id: 'guest456', created_at: 30.minutes.ago)

        # Create old empty user cart (should not be deleted)
        old_user_cart = create(:cart, user: user, created_at: 2.hours.ago)

        expect {
          CartCleanupJob.perform_now
        }.to change { Cart.count }.by(-1)

        expect { old_empty_cart.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(recent_empty_cart.reload).to be_present
        expect(old_user_cart.reload).to be_present
      end

      it 'does not delete guest carts with items' do
        old_cart_with_items = create(:cart, user: nil, session_id: 'guest789', created_at: 2.hours.ago)
        create(:cart_item, cart: old_cart_with_items)

        expect {
          CartCleanupJob.perform_now
        }.not_to change { Cart.count }

        expect(old_cart_with_items.reload).to be_present
      end
    end

    describe 'old guest cart abandonment' do
      it 'abandons guest carts with items older than 7 days' do
        old_cart = create(:cart,
          user: nil,
          session_id: 'guest_old',
          status: 'active',
          created_at: 8.days.ago
        )
        create(:cart_item, cart: old_cart)

        # Recent cart with items (should not be abandoned)
        recent_cart = create(:cart,
          user: nil,
          session_id: 'guest_recent',
          status: 'active',
          created_at: 3.days.ago
        )
        create(:cart_item, cart: recent_cart)

        CartCleanupJob.perform_now

        expect(old_cart.reload.status).to eq('abandoned')
        expect(recent_cart.reload.status).to eq('active')
      end

      it 'does not abandon user carts' do
        old_user_cart = create(:cart,
          user: user,
          status: 'active',
          created_at: 8.days.ago
        )
        create(:cart_item, cart: old_user_cart)

        CartCleanupJob.perform_now

        expect(old_user_cart.reload.status).to eq('active')
      end
    end

    describe 'expired cart cleanup' do
      it 'abandons expired carts' do
        expired_cart = create(:cart,
          user: user,
          status: 'active'
        )
        # Update expires_at after creation to avoid callback overwriting it
        expired_cart.update!(expires_at: 1.hour.ago)

        active_cart = create(:cart,
          user: user,
          status: 'active'
        )
        active_cart.update!(expires_at: 1.hour.from_now)

        CartCleanupJob.perform_now

        expect(expired_cart.reload.status).to eq('abandoned')
        expect(active_cart.reload.status).to eq('active')
      end

      it 'does not affect already abandoned or converted carts' do
        abandoned_cart = create(:cart,
          user: user,
          status: 'abandoned',
          expires_at: 1.hour.ago
        )

        converted_cart = create(:cart,
          user: user,
          status: 'converted',
          expires_at: 1.hour.ago
        )

        expect {
          CartCleanupJob.perform_now
        }.not_to change { [abandoned_cart.reload.status, converted_cart.reload.status] }
      end
    end

    describe 'logging' do
      it 'logs the cleanup process' do
        # Create test data
        create(:cart, user: nil, session_id: 'empty_old', created_at: 2.hours.ago)

        old_cart_with_items = create(:cart, user: nil, session_id: 'old_items', status: 'active', created_at: 8.days.ago)
        create(:cart_item, cart: old_cart_with_items)

        expired_cart = create(:cart, user: user, status: 'active')
        expired_cart.update!(expires_at: 1.hour.ago)

        # Just verify that logging happens, not exact messages
        expect(Rails.logger).to receive(:info).at_least(:once)

        CartCleanupJob.perform_now
      end
    end

    describe 'error handling' do
      it 'logs errors and re-raises them' do
        allow(Cart).to receive(:guest_carts).and_raise(StandardError, 'Database error')

        expect(Rails.logger).to receive(:error).at_least(:once)

        expect {
          CartCleanupJob.perform_now
        }.to raise_error(StandardError, 'Database error')
      end
    end

    describe 'job queuing' do
      it 'queues to the background queue' do
        expect(CartCleanupJob.new.queue_name).to eq('background')
      end

      it 'can be enqueued for later execution' do
        expect {
          CartCleanupJob.perform_later
        }.to have_enqueued_job(CartCleanupJob).on_queue('background')
      end
    end

    describe 'complex scenarios' do
      it 'handles multiple cleanup criteria simultaneously' do
        # Empty old guest cart (should be deleted)
        empty_old = create(:cart, user: nil, session_id: 'empty_old', created_at: 2.hours.ago)

        # Old guest cart with items (should be abandoned)
        old_with_items = create(:cart, user: nil, session_id: 'old_items', status: 'active', created_at: 8.days.ago)
        create(:cart_item, cart: old_with_items)

        # Expired user cart (should be abandoned)
        expired_user = create(:cart, user: user, status: 'active')
        expired_user.update!(expires_at: 1.hour.ago)

        # Recent active cart (should remain unchanged)
        recent_active = create(:cart, user: user, status: 'active', created_at: 1.hour.ago)

        CartCleanupJob.perform_now

        expect { empty_old.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(old_with_items.reload.status).to eq('abandoned')
        expect(expired_user.reload.status).to eq('abandoned')
        expect(recent_active.reload.status).to eq('active')
      end

      it 'handles edge cases with nil values gracefully' do
        # Cart with nil expires_at
        cart_no_expiry = create(:cart, user: user, status: 'active', expires_at: nil)

        # Cart with nil user_id (guest cart) - ensure it has items to prevent deletion
        guest_cart = create(:cart, user: nil, session_id: 'guest', status: 'active', created_at: 1.day.ago)
        create(:cart_item, cart: guest_cart) # Add item so it won't be deleted

        expect {
          CartCleanupJob.perform_now
        }.not_to raise_error

        expect(cart_no_expiry.reload.status).to eq('active')
        # Guest cart older than 7 days with items should be abandoned, 1 day old should remain active
        expect(guest_cart.reload.status).to eq('active')
      end
    end
  end
end
