class WebhooksController < ApplicationController
  protect_from_forgery except: [:stripe]
  before_action :verify_stripe_signature, only: [:stripe]

  def stripe
    case @event['type']
    when 'payment_intent.succeeded'
      handle_successful_payment
    when 'payment_intent.payment_failed'
      handle_failed_payment
    when 'payment_intent.canceled'
      handle_canceled_payment
    else
      Rails.logger.info "Unhandled Stripe webhook event type: #{@event['type']}"
    end

    head :ok
  rescue => e
    Rails.logger.error "Stripe webhook error: #{e.message}"
    head :bad_request
  end

  private

  def verify_stripe_signature
    payload = request.body.read
    signature = request.env['HTTP_STRIPE_SIGNATURE']
    
    webhook_secret = Rails.application.credentials.stripe&.dig(:webhook_secret) ||
                     ENV['STRIPE_WEBHOOK_SECRET']

    begin
      @event = Stripe::Webhook.construct_event(
        payload, signature, webhook_secret
      )
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON in Stripe webhook: #{e.message}"
      head :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Invalid Stripe webhook signature: #{e.message}"
      head :bad_request
      return
    end
  end

  def handle_successful_payment
    payment_intent_id = @event['data']['object']['id']
    PaymentService.confirm_payment(payment_intent_id)
    
    Rails.logger.info "Payment succeeded for payment intent: #{payment_intent_id}"
  end

  def handle_failed_payment
    payment_intent_id = @event['data']['object']['id']
    order = Order.find_by(stripe_payment_intent_id: payment_intent_id)
    
    if order
      order.update!(
        status: :cancelled,
        payment_status: :payment_pending
      )
      
      # Optionally notify customer of failed payment
      OrderMailer.payment_failed_notification(order).deliver_later if defined?(OrderMailer)
    end
    
    Rails.logger.error "Payment failed for payment intent: #{payment_intent_id}"
  end

  def handle_canceled_payment
    payment_intent_id = @event['data']['object']['id']
    order = Order.find_by(stripe_payment_intent_id: payment_intent_id)
    
    if order
      order.update!(
        status: :cancelled,
        payment_status: :payment_pending
      )
    end
    
    Rails.logger.info "Payment canceled for payment intent: #{payment_intent_id}"
  end
end
