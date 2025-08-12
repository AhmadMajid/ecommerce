module SessionHelpers
  # Helper for creating authenticated user sessions in request specs
  def create_authenticated_session(user)
    # Ensure user is confirmed
    user.update!(confirmed_at: Time.current) unless user.confirmed_at

    # Sign in using Devise
    sign_in user

    # Create or find active cart
    cart = user.carts.active.first_or_create!(status: 'active')

    # Mock the session-dependent methods
    mock_session_methods(user, cart)

    cart
  end

  # Helper for creating guest cart sessions
  def create_guest_cart_session
    cart = FactoryBot.create(:cart, user: nil, status: 'active')
    mock_session_methods(nil, cart)
    cart
  end

  # Mock session for request specs that need it
  def mock_session_methods(user, cart)
    # Mock authentication methods
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(!!user)
    allow_any_instance_of(ApplicationController).to receive(:current_cart).and_return(cart)

    # Mock session hash
    session_data = {}
    session_data[:cart_id] = cart.id if cart
    session_data[:user_id] = user.id if user

    allow_any_instance_of(ApplicationController).to receive(:session).and_return(session_data)
  end
end

RSpec.configure do |config|
  config.include SessionHelpers, type: :request
  config.include SessionHelpers, type: :feature
end