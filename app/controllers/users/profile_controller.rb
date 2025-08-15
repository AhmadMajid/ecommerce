class Users::ProfileController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    # Load user's recent orders and wishlist items for dashboard
    @recent_orders = current_user.orders.recent.limit(5) if current_user.respond_to?(:orders)
    @wishlist_items = current_user.wishlists.includes(:product).limit(5)
    @address_count = current_user.addresses.count
  end

  def edit
    # Prepare form data
    @addresses = current_user.addresses.order(:created_at)
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: 'Profile updated successfully!'
    else
      @addresses = current_user.addresses.order(:created_at)
      render :edit, status: :unprocessable_entity
    end
  end

  def update_password
    if @user.update_with_password(password_params)
      bypass_sign_in(@user)
      redirect_to profile_path, notice: 'Password updated successfully!'
    else
      @addresses = current_user.addresses.order(:created_at)
      render :edit, status: :unprocessable_entity
    end
  end

  def update_preferences
    if @user.update(preference_params)
      redirect_to profile_path, notice: 'Preferences updated successfully!'
    else
      @addresses = current_user.addresses.order(:created_at)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :phone, :date_of_birth)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  def preference_params
    params.require(:user).permit(:email_notifications, :marketing_emails)
  end
end
