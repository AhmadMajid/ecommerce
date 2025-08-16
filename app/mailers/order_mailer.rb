class OrderMailer < ApplicationMailer
  def confirmation_email(order)
    @order = order
    @user = order.user
    
    mail(
      to: order.email,
      subject: "Order Confirmation - #{@order.order_number}"
    )
  end

  def payment_failed_notification(order)
    @order = order
    @user = order.user
    
    mail(
      to: order.email,
      subject: "Payment Issue - #{@order.order_number}"
    )
  end

  def refund_notification(order, refund)
    @order = order
    @user = order.user
    @refund = refund
    
    mail(
      to: order.email,
      subject: "Refund Processed - #{@order.order_number}"
    )
  end
end
