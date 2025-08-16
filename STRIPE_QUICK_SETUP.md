# STRIPE TEST SETUP - IMMEDIATE TESTING
# For quick development setup, add these to your environment

# 1. Add to .env file (create if doesn't exist):
STRIPE_PUBLISHABLE_KEY=pk_test_51YOUR_KEY_HERE
STRIPE_SECRET_KEY=sk_test_51YOUR_KEY_HERE
STRIPE_WEBHOOK_SECRET=whsec_YOUR_WEBHOOK_SECRET_HERE

# 2. Or export in terminal for immediate testing:
export STRIPE_PUBLISHABLE_KEY=pk_test_51YOUR_ACTUAL_KEY_HERE
export STRIPE_SECRET_KEY=sk_test_51YOUR_ACTUAL_KEY_HERE
export STRIPE_WEBHOOK_SECRET=whsec_YOUR_ACTUAL_WEBHOOK_SECRET_HERE

# Quick Test Cards:
# Success: 4242424242424242
# Decline: 4000000000000002
# Use any future expiry date (12/25) and any CVC (123)

# Get your keys from: https://dashboard.stripe.com/test/apikeys
