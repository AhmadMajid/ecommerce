require 'rails_helper'

RSpec.describe WebhooksController, type: :request do
  let(:valid_payload) { '{"id": "evt_test_webhook", "object": "event"}' }
  let(:valid_signature) { 'test_signature' }
  let(:webhook_secret) { 'whsec_test_secret' }
  
  before do
    allow(ENV).to receive(:[]).with('STRIPE_WEBHOOK_SECRET').and_return(webhook_secret)
  end

  describe 'POST /webhooks/stripe' do
    let(:payment_intent_id) { 'pi_test123' }
    let(:order) { create(:order, stripe_payment_intent_id: payment_intent_id) }
    
    before do
      order # Ensure order exists
    end

    context 'with valid signature' do
      let(:event) do
        {
          'id' => 'evt_test',
          'type' => 'payment_intent.succeeded',
          'data' => {
            'object' => {
              'id' => payment_intent_id
            }
          }
        }
      end

      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
        allow(PaymentService).to receive(:confirm_payment)
      end

      it 'handles payment_intent.succeeded' do
        post '/webhooks/stripe', 
             params: valid_payload, 
             headers: { 'HTTP_STRIPE_SIGNATURE' => valid_signature }

        expect(response).to have_http_status(:ok)
        expect(PaymentService).to have_received(:confirm_payment).with(payment_intent_id)
      end

      context 'with payment_intent.payment_failed event' do
        let(:event) do
          {
            'id' => 'evt_test',
            'type' => 'payment_intent.payment_failed',
            'data' => {
              'object' => {
                'id' => payment_intent_id
              }
            }
          }
        end

        before do
          allow(OrderMailer).to receive(:payment_failed_notification).and_return(double(deliver_later: true))
        end

        it 'updates order status and sends email' do
          post '/webhooks/stripe', 
               params: valid_payload, 
               headers: { 'HTTP_STRIPE_SIGNATURE' => valid_signature }

          expect(response).to have_http_status(:ok)
          
          order.reload
          expect(order.status).to eq('cancelled')
          expect(order.payment_status).to eq('payment_pending')
        end
      end

      context 'with payment_intent.canceled event' do
        let(:event) do
          {
            'id' => 'evt_test',
            'type' => 'payment_intent.canceled',
            'data' => {
              'object' => {
                'id' => payment_intent_id
              }
            }
          }
        end

        it 'updates order status' do
          post '/webhooks/stripe', 
               params: valid_payload, 
               headers: { 'HTTP_STRIPE_SIGNATURE' => valid_signature }

          expect(response).to have_http_status(:ok)
          
          order.reload
          expect(order.status).to eq('cancelled')
          expect(order.payment_status).to eq('payment_pending')
        end
      end

      context 'with unhandled event type' do
        let(:event) do
          {
            'id' => 'evt_test',
            'type' => 'customer.created',
            'data' => {
              'object' => {
                'id' => 'cus_test123'
              }
            }
          }
        end

        it 'returns ok without processing' do
          post '/webhooks/stripe', 
               params: valid_payload, 
               headers: { 'HTTP_STRIPE_SIGNATURE' => valid_signature }

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'with invalid signature' do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(Stripe::SignatureVerificationError.new('Invalid signature'))
      end

      it 'returns bad request' do
        post '/webhooks/stripe', 
             params: valid_payload, 
             headers: { 'HTTP_STRIPE_SIGNATURE' => 'invalid_signature' }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'with invalid JSON' do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(JSON::ParserError.new('Invalid JSON'))
      end

      it 'returns bad request' do
        post '/webhooks/stripe', 
             params: 'invalid json', 
             headers: { 'HTTP_STRIPE_SIGNATURE' => valid_signature }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'with processing error' do
      let(:event) do
        {
          'id' => 'evt_test',
          'type' => 'payment_intent.succeeded',
          'data' => {
            'object' => {
              'id' => payment_intent_id
            }
          }
        }
      end

      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
        allow(PaymentService).to receive(:confirm_payment).and_raise(StandardError.new('Processing error'))
      end

      it 'returns bad request' do
        post '/webhooks/stripe', 
             params: valid_payload, 
             headers: { 'HTTP_STRIPE_SIGNATURE' => valid_signature }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
