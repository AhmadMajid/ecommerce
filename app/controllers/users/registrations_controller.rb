class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /users/sign_up
  def new
    super
  end

  # POST /users
  def create
    super
  end

  # GET /users/edit
  def edit
    super
  end

  # PUT /users
  def update
    super
  end

  # DELETE /users
  def destroy
    super
  end

  protected

  # Configure permitted parameters for sign up
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name, :last_name, :phone, :date_of_birth
    ])
  end

  # Configure permitted parameters for account update
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name, :last_name, :phone, :date_of_birth
    ])
  end

  # Redirect after successful registration
  def after_sign_up_path_for(resource)
    flash[:notice] = "Welcome! Please check your email to confirm your account."
    root_path
  end

  # Redirect after successful account update
  def after_update_path_for(resource)
    flash[:notice] = "Your account has been updated successfully."
    edit_user_registration_path
  end
end
