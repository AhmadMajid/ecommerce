class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /users/sign_in
  def new
    super
  end

  # POST /users/sign_in
  def create
    super
  end

  # DELETE /users/sign_out
  def destroy
    super
  end

  protected

  # Redirect after successful sign in
  def after_sign_in_path_for(resource)
    stored_location_for(resource) ||
    (resource.admin? ? admin_dashboard_path : root_path) rescue root_path
  end

  # Redirect after sign out
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
