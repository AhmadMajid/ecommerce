class Users::UnlocksController < Devise::UnlocksController
  # GET /users/unlock/new
  def new
    super
  end

  # POST /users/unlock
  def create
    super
  end

  # GET /users/unlock?unlock_token=abcdef
  def show
    super
  end

  protected

  # Redirect after unlocking
  def after_unlock_path_for(resource)
    flash[:notice] = "Your account has been unlocked successfully. You can now sign in."
    new_session_path(resource)
  end

  # Redirect after sending unlock instructions
  def after_sending_unlock_instructions_path_for(resource)
    flash[:notice] = "If your account exists, you will receive an email with instructions for how to unlock it in a few minutes."
    new_session_path(resource)
  end
end
