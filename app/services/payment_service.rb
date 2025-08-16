class PaymentService
  class << self
    def create_payment_intent(order)
      stripe_params = {
        amount: order.total_in_cents,
        currency: order.currency&.downcase || 'usd',
        payment_method_types: ['card'],
        metadata: {
          order_id: order.id,
          order_number: order.order_number,
          user_id: order.user_id
        }
      }

      # Create or retrieve Stripe customer
      if order.user.present?
        stripe_customer = find_or_create_stripe_customer(order.user)
        stripe_params[:customer] = stripe_customer.id
        order.update!(stripe_customer_id: stripe_customer.id)
      end

      # Create payment intent
      payment_intent = Stripe::PaymentIntent.create(stripe_params)
      
      # Update order with payment intent ID
      order.update!(stripe_payment_intent_id: payment_intent.id)
      
      payment_intent
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error creating payment intent: #{e.message}"
      raise PaymentError, "Unable to create payment: #{e.message}"
    end

    def confirm_payment(payment_intent_id)
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
      order = Order.find_by(stripe_payment_intent_id: payment_intent_id)
      
      return unless order

      case payment_intent.status
      when 'succeeded'
        order.update!(
          status: :confirmed,
          payment_status: :paid
        )
        OrderMailer.confirmation_email(order).deliver_later
        true
      when 'requires_payment_method'
        order.update!(payment_status: :payment_pending)
        false
      when 'canceled'
        order.update!(
          status: :cancelled,
          payment_status: :payment_pending
        )
        false
      else
        false
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error confirming payment: #{e.message}"
      false
    end

    def refund_payment(order, amount = nil)
      return false unless order.stripe_payment_intent_id

      refund_params = {
        payment_intent: order.stripe_payment_intent_id
      }
      
      refund_params[:amount] = (amount * 100).to_i if amount

      refund = Stripe::Refund.create(refund_params)
      
      if refund.status == 'succeeded'
        if amount && amount < order.total
          order.update!(payment_status: :partially_refunded)
        else
          order.update!(
            status: :refunded,
            payment_status: :payment_refunded
          )
        end
        
        OrderMailer.refund_notification(order, refund).deliver_later
        true
      else
        false
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error processing refund: #{e.message}"
      false
    end

    private

    def find_or_create_stripe_customer(user)
      # Check if user already has a Stripe customer ID
      existing_customer = user.orders.where.not(stripe_customer_id: nil).first&.stripe_customer_id
      
      if existing_customer
        begin
          return Stripe::Customer.retrieve(existing_customer)
        rescue Stripe::InvalidRequestError
          # Customer doesn't exist in Stripe, create a new one
        end
      end

      # Create new Stripe customer
      Stripe::Customer.create(
        email: user.email,
        name: user.full_name,
        metadata: {
          user_id: user.id
        }
      )
    end
  end

  class PaymentError < StandardError; end
end
