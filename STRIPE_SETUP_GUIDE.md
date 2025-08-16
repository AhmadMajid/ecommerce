# Stripe Test API Keys Setup Guide

## Step 1: Get Your Stripe Test Keys

1. Go to https://dashboard.stripe.com/test/apikeys
2. Sign up or log in to your Stripe account
3. Make sure you're in **Test mode** (toggle in top left)
4. Copy your:
   - **Publishable key** (starts with `pk_test_`)
   - **Secret key** (starts with `sk_test_`)

## Step 2: Add Keys to Your Rails App

You have two options:

### Option A: Using Environment Variables (Recommended)

1. Create or edit your `.env` file in the project root:
```bash
# Add to .env file
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
```

2. Make sure `.env` is in your `.gitignore` file (it already is)

### Option B: Using Rails Credentials (More Secure)

1. Edit encrypted credentials:
```bash
EDITOR="code --wait" rails credentials:edit
```

2. Add your keys:
```yaml
stripe:
  publishable_key: pk_test_your_publishable_key_here
  secret_key: sk_test_your_secret_key_here
```

3. Save and close the file

## Step 3: Test the Setup

1. Start your Rails server:
```bash
bin/rails server
```

2. Check if Stripe keys are loaded by opening Rails console:
```bash
bin/rails console
```

3. Test in console:
```ruby
# Check if keys are loaded
puts Rails.application.config.stripe_publishable_key
puts Stripe.api_key

# Test API connection
Stripe::Account.retrieve
```

## Step 4: Test Stripe Payment

1. Add items to cart and proceed to checkout
2. Use Stripe's test card numbers:
   - Success: `4242 4242 4242 4242`
   - Declined: `4000 0000 0000 0002`
   - Requires authentication: `4000 0025 0000 3155`
3. Use any future expiry date (e.g., 12/34)
4. Use any 3-digit CVC

## Test Card Numbers

| Card Number | Description |
|-------------|-------------|
| 4242 4242 4242 4242 | Visa - Success |
| 4000 0000 0000 0002 | Visa - Declined |
| 4000 0025 0000 3155 | Visa - Requires authentication |
| 5555 5555 5555 4444 | Mastercard - Success |

## Webhooks (Optional)

If you want to test webhooks locally:

1. Install Stripe CLI: https://stripe.com/docs/stripe-cli
2. Login: `stripe login`
3. Forward events: `stripe listen --forward-to localhost:3000/webhooks/stripe`
4. Copy the webhook signing secret to your environment

## Production Setup

When ready for production:

1. Switch to live keys from https://dashboard.stripe.com/apikeys
2. Update your production environment variables
3. Set up production webhooks in Stripe Dashboard

## Current Configuration

Your Rails app is configured to:
- Use Stripe API version 2023-10-16
- Load keys from credentials or environment variables
- Log requests in development mode
- Handle webhooks at `/webhooks/stripe`

The payment system includes:
- ✅ Payment intents for secure processing
- ✅ Order management with Stripe integration
- ✅ Webhook handling for payment confirmations
- ✅ Multi-step checkout flow
- ✅ Error handling and validation
