module RequestSpecHelpers
  # Comprehensive authentication helper for request specs
  def authenticate_user(user)
    # Ensure the user is properly confirmed for Devise
    if user.confirmed_at.nil?
      user.update!(confirmed_at: Time.current)
    end

    # Create and set up an active cart for the user
    cart = user.carts.active.first_or_create!(status: 'active')

    # Mock the application controller methods to ensure consistency
    mock_authentication_methods(user, cart)

    cart
  end

  def authenticate_guest_with_cart
    # Create a guest cart
    cart = FactoryBot.create(:cart, user: nil, status: 'active')

    # Mock the guest session
    mock_authentication_methods(nil, cart)

    cart
  end

  private

  def mock_authentication_methods(user, cart)
    # Mock all the authentication and cart-related methods
    # Since Devise methods are dynamically included, we need to use a different approach

    # For controllers that include Devise functionality
    allow_any_instance_of(CartItemsController).to receive(:current_user).and_return(user)
    allow_any_instance_of(CartItemsController).to receive(:user_signed_in?).and_return(!!user)
    allow_any_instance_of(CartItemsController).to receive(:current_cart).and_return(cart)
    allow_any_instance_of(CartItemsController).to receive(:authenticate_user!).and_return(true)

    allow_any_instance_of(CartsController).to receive(:current_user).and_return(user)
    allow_any_instance_of(CartsController).to receive(:user_signed_in?).and_return(!!user)
    allow_any_instance_of(CartsController).to receive(:current_cart).and_return(cart)
    allow_any_instance_of(CartsController).to receive(:authenticate_user!).and_return(true)

    # Mock specific controller methods for cart and checkout controllers
    [CartItemsController, CartsController, CheckoutController].each do |controller_class|
      allow_any_instance_of(controller_class).to receive(:current_user).and_return(user)
      allow_any_instance_of(controller_class).to receive(:user_signed_in?).and_return(!!user)
      allow_any_instance_of(controller_class).to receive(:current_cart).and_return(cart)
      allow_any_instance_of(controller_class).to receive(:authenticate_user!).and_return(true)
    end

    # Mock cart-related methods
    if cart
      allow(cart).to receive(:items).and_return(cart.cart_items)
      allow(cart).to receive_message_chain(:items, :empty?).and_return(cart.cart_items.empty?)
    end
  end
end

RSpec.configure do |config|
  config.include RequestSpecHelpers, type: :request
end