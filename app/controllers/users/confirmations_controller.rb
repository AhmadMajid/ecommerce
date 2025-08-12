class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /users/confirmation/new
  def new
    super
  end

  # POST /users/confirmation
  def create
    super
  end

  # GET /users/confirmation?confirmation_token=abcdef
  def show
    super
  end

  protected

  # Redirect after confirmation
  def after_confirmation_path_for(resource_name, resource)
    flash[:notice] = "Your email has been successfully confirmed! Welcome to our store."
    sign_in(resource)
    root_path
  end

  # Redirect after resending confirmation instructions
  def after_resending_confirmation_instructions_path_for(resource_name)
    flash[:notice] = "A new confirmation link has been sent to your email address."
    new_session_path(resource_name)
  end
end
