class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show]

  def index
    @orders = current_user.orders
                          .recent
                          .includes(:order_items)
                          .page(params[:page])
                          .per(10)
  end

  def show
    # Ensure user can only see their own orders
    unless @order.user == current_user
      redirect_to orders_path, alert: 'Order not found.'
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to orders_path, alert: 'Order not found.'
  end
end
