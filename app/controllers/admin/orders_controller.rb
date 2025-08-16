class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: [:show, :edit, :update, :cancel, :refund]

  def index
    @orders = Order.includes(:user, :order_items)
                   .recent
                   .page(params[:page])
                   .per(20)
                   
    @orders = @orders.by_status(params[:status]) if params[:status].present?
  end

  def show
    @payment_intent = @order.payment_intent if @order.stripe_payment_intent_id
  end

  def edit
  end

  def update
    if @order.update(order_params)
      redirect_to admin_order_path(@order), notice: 'Order updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def cancel
    if @order.can_be_cancelled?
      @order.update!(status: :cancelled)
      redirect_to admin_order_path(@order), notice: 'Order cancelled successfully.'
    else
      redirect_to admin_order_path(@order), alert: 'Order cannot be cancelled.'
    end
  end

  def refund
    amount = params[:refund_amount].to_f
    amount = nil if amount <= 0 || amount >= @order.total

    if PaymentService.refund_payment(@order, amount)
      redirect_to admin_order_path(@order), notice: 'Refund processed successfully.'
    else
      redirect_to admin_order_path(@order), alert: 'Refund failed. Please try again.'
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:status, :notes, :shipped_at, :delivered_at)
  end
end
