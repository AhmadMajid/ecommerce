# Stripe Configuration
stripe_credentials = Rails.application.credentials.stripe || {}

Stripe.api_key = stripe_credentials[:secret_key] || ENV['STRIPE_SECRET_KEY']

# Set API version for consistency
Stripe.api_version = '2023-10-16'

# Log Stripe requests in development
if Rails.env.development?
  Stripe.log_level = Stripe::LEVEL_INFO
end

# Store publishable key for views (we'll access this via helper method)
Rails.application.config.stripe_publishable_key = stripe_credentials[:publishable_key] || ENV['STRIPE_PUBLISHABLE_KEY']
