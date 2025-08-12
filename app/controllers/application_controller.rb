class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization

  # Protect from CSRF attacks
  protect_from_forgery with: :exception

  # Configure Devise permitted parameters
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Redirect users after sign in
  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_dashboard_path rescue root_path
    else
      root_path
    end
  end

  # Redirect users after sign up
  def after_sign_up_path_for(resource)
    root_path
  end

  # Set current user for Pundit
  def pundit_user
    current_user
  end

  # Make current_cart available to all views
  helper_method :current_cart

  protected

  def configure_permitted_parameters
    # Permit additional fields for sign up
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name, :last_name, :phone, :date_of_birth
    ])

    # Permit additional fields for account update
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name, :last_name, :phone, :date_of_birth
    ])
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  # Get or create current cart (session-based for guests, persistent for users)
  def current_cart
    if user_signed_in?
      # For logged-in users, get or create their active cart
      cart = current_user.carts.active.first
      if cart.nil?
        cart = current_user.carts.create!(
          status: 'active',
          session_id: session.id,
          currency: 'USD'
        )
      end

      # Merge guest cart if exists
      guest_cart_id = session[:guest_cart_id]
      if guest_cart_id.present?
        guest_cart = Cart.find_by(id: guest_cart_id, user_id: nil)
        if guest_cart && guest_cart != cart
          cart.merge_with!(guest_cart)
          session[:guest_cart_id] = nil
        end
      end

      cart
    else
      # For guests, use session-based cart
      cart_id = session[:guest_cart_id]
      cart = cart_id ? Cart.find_by(id: cart_id, user_id: nil) : nil

      if cart.nil? || cart.expired?
        # Ensure we have a session ID for guest carts
        session_id_value = session.id || SecureRandom.hex(16)
        cart = Cart.create!(
          user_id: nil,
          session_id: session_id_value,
          status: 'active',
          currency: 'USD'
        )
        session[:guest_cart_id] = cart.id
      end

      cart
    end
  end

  # Check if user is admin
  def require_admin
    unless current_user&.admin?
      flash[:alert] = "Access denied. Admin privileges required."
      redirect_to root_path
    end
  end

  # Check if user is authenticated
  def authenticate_user_with_redirect!
    unless user_signed_in?
      flash[:alert] = "Please sign in to continue."
      redirect_to new_user_session_path
    end
  end
end
