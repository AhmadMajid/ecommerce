class Users::PasswordsController < Devise::PasswordsController
  # GET /users/password/new
  def new
    super
  end

  # POST /users/password
  def create
    super
  end

  # GET /users/password/edit?reset_password_token=abcdef
  def edit
    super
  end

  # PUT /users/password
  def update
    super
  end

  protected

  # Redirect after password reset
  def after_resetting_password_path_for(resource)
    flash[:notice] = "Your password has been changed successfully. You are now signed in."
    root_path
  end

  # Redirect after sending reset password instructions
  def after_sending_reset_password_instructions_path_for(resource_name)
    flash[:notice] = "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."
    new_session_path(resource_name)
  end
end
