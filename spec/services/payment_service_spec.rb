require 'rails_helper'

RSpec.describe PaymentService do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user, total: 50.00) }

  before do
    # Mock Stripe API key
    allow(Rails.application.credentials).to receive(:stripe).and_return({
      secret_key: 'sk_test_mock_key',
      publishable_key: 'pk_test_mock_key'
    })
    Stripe.api_key = 'sk_test_mock_key'
  end

  describe '.create_payment_intent' do
    it 'creates a Stripe payment intent' do
      # Mock Stripe API
      stripe_customer = double('Stripe::Customer', id: 'cus_test123')
      payment_intent = double('Stripe::PaymentIntent', id: 'pi_test123')
      
      allow(described_class).to receive(:find_or_create_stripe_customer).and_return(stripe_customer)
      allow(Stripe::PaymentIntent).to receive(:create).and_return(payment_intent)

      result = described_class.create_payment_intent(order)

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        hash_including(
          amount: 5000, # $50.00 in cents
          currency: 'usd',
          payment_method_types: ['card'],
          customer: 'cus_test123',
          metadata: {
            order_id: order.id,
            order_number: order.order_number,
            user_id: order.user_id
          }
        )
      )
      expect(result).to eq(payment_intent)
    end

    it 'handles Stripe errors' do
      # Ensure Stripe methods are properly mocked
      allow(Stripe::Customer).to receive(:create).and_raise(
        Stripe::CardError.new('Card declined', 'card_declined')
      )
      allow(Stripe::PaymentIntent).to receive(:create).and_raise(
        Stripe::CardError.new('Card declined', 'card_declined')
      )

      expect {
        described_class.create_payment_intent(order)
      }.to raise_error(PaymentService::PaymentError, 'Unable to create payment: Card declined')
    end
  end

  describe '.confirm_payment' do
    let(:payment_intent_id) { 'pi_test123' }

    context 'with successful payment' do
      before do
        order.update!(stripe_payment_intent_id: payment_intent_id)
        
        payment_intent = double('Stripe::PaymentIntent', status: 'succeeded')
        allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(payment_intent)
        allow(OrderMailer).to receive(:confirmation_email).and_return(double(deliver_later: true))
      end

      it 'updates order status to confirmed' do
        result = described_class.confirm_payment(payment_intent_id)

        expect(result).to be true
        order.reload
        expect(order.status).to eq('confirmed')
        expect(order.payment_status).to eq('paid')
      end

      it 'sends confirmation email' do
        described_class.confirm_payment(payment_intent_id)
        expect(OrderMailer).to have_received(:confirmation_email).with(order)
      end
    end

    context 'with failed payment' do
      before do
        order.update!(stripe_payment_intent_id: payment_intent_id)
        
        payment_intent = double('Stripe::PaymentIntent', status: 'requires_payment_method')
        allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(payment_intent)
      end

      it 'updates payment status to pending' do
        result = described_class.confirm_payment(payment_intent_id)

        expect(result).to be false
        order.reload
        expect(order.payment_status).to eq('payment_pending')
      end
    end

    context 'with canceled payment' do
      before do
        order.update!(stripe_payment_intent_id: payment_intent_id)
        
        payment_intent = double('Stripe::PaymentIntent', status: 'canceled')
        allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(payment_intent)
      end

      it 'updates order status to cancelled' do
        result = described_class.confirm_payment(payment_intent_id)

        expect(result).to be false
        order.reload
        expect(order.status).to eq('cancelled')
        expect(order.payment_status).to eq('payment_pending')
      end
    end

    context 'with non-existent order' do
      it 'returns false gracefully' do
        payment_intent = double('Stripe::PaymentIntent', status: 'succeeded')
        allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(payment_intent)

        result = described_class.confirm_payment('pi_nonexistent')
        expect(result).to be_nil
      end
    end

    it 'handles Stripe errors' do
      allow(Stripe::PaymentIntent).to receive(:retrieve).and_raise(
        Stripe::InvalidRequestError.new('Invalid payment intent', 'payment_intent')
      )

      result = described_class.confirm_payment(payment_intent_id)
      expect(result).to be false
    end
  end

  describe '.refund_payment' do
    let(:payment_intent_id) { 'pi_test123' }

    before do
      order.update!(stripe_payment_intent_id: payment_intent_id)
    end

    context 'with successful refund' do
      let(:refund) { double('Stripe::Refund', status: 'succeeded') }

      before do
        allow(Stripe::Refund).to receive(:create).and_return(refund)
        allow(OrderMailer).to receive(:refund_notification).and_return(double(deliver_later: true))
      end

      it 'processes full refund' do
        result = described_class.refund_payment(order)

        expect(Stripe::Refund).to have_received(:create).with(
          payment_intent: payment_intent_id
        )
        expect(result).to be true
        
        order.reload
        expect(order.status).to eq('refunded')
        expect(order.payment_status).to eq('payment_refunded')
      end

      it 'processes partial refund' do
        result = described_class.refund_payment(order, 25.00)

        expect(Stripe::Refund).to have_received(:create).with(
          payment_intent: payment_intent_id,
          amount: 2500
        )
        expect(result).to be true
        
        order.reload
        expect(order.payment_status).to eq('partially_refunded')
      end

      it 'sends refund notification email' do
        described_class.refund_payment(order)
        expect(OrderMailer).to have_received(:refund_notification).with(order, refund)
      end
    end

    context 'with failed refund' do
      before do
        refund = double('Stripe::Refund', status: 'failed')
        allow(Stripe::Refund).to receive(:create).and_return(refund)
      end

      it 'returns false' do
        result = described_class.refund_payment(order)
        expect(result).to be false
      end
    end

    context 'without payment intent' do
      before do
        order.update!(stripe_payment_intent_id: nil)
      end

      it 'returns false' do
        result = described_class.refund_payment(order)
        expect(result).to be false
      end
    end

    it 'handles Stripe errors' do
      allow(Stripe::Refund).to receive(:create).and_raise(
        Stripe::InvalidRequestError.new('Already refunded', 'charge')
      )

      result = described_class.refund_payment(order)
      expect(result).to be false
    end
  end
end
