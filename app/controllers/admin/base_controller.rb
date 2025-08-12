class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  layout 'admin'

  protected

  def ensure_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end

  def admin_breadcrumb
    @breadcrumb ||= []
  end

  def add_breadcrumb(name, path = nil)
    admin_breadcrumb << { name: name, path: path }
  end
end
