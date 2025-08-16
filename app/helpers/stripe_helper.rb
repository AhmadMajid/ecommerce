module StripeHelper
  def stripe_publishable_key
    Rails.application.config.stripe_publishable_key
  end
end
