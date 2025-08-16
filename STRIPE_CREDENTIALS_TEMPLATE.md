# Add these to your Rails credentials file:
# Run: EDITOR='code --wait' bin/rails credentials:edit
# And add:

stripe:
  publishable_key: pk_test_your_publishable_key_here
  secret_key: sk_test_your_secret_key_here
  webhook_secret: whsec_your_webhook_secret_here

# For production, use live keys:
# publishable_key: pk_live_your_live_publishable_key
# secret_key: sk_live_your_live_secret_key
