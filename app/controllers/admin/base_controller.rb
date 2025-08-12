class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  layout 'admin'

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protected

  def record_not_found
    render file: Rails.root.join('public', '404.html'), status: :not_found, layout: false
  end

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
