class CartCleanupJob < ApplicationJob
  queue_as :background

  def perform
    Rails.logger.info "Starting cart cleanup job..."

    # Delete empty guest carts older than 1 hour
    empty_guest_carts = Cart.guest_carts
                           .joins("LEFT JOIN cart_items ON carts.id = cart_items.cart_id")
                           .where("cart_items.id IS NULL")
                           .where("carts.created_at < ?", 1.hour.ago)

    deleted_count = empty_guest_carts.delete_all
    Rails.logger.info "Cart cleanup: deleted #{deleted_count} empty guest carts"

    # Abandon old guest carts with items (older than 7 days)
    old_guest_carts_with_items = Cart.guest_carts
                                    .active
                                    .where("carts.created_at < ?", 7.days.ago)
                                    .where("id IN (?)",
                                           Cart.joins(:cart_items).distinct.pluck(:id))

    abandoned_count = old_guest_carts_with_items.update_all(status: 'abandoned')
    Rails.logger.info "Cart cleanup: abandoned #{abandoned_count} old guest carts with items"

    # Also clean up expired carts
    expired_count = Cart.expired.active.update_all(status: 'abandoned')
    Rails.logger.info "Cart cleanup: abandoned #{expired_count} expired carts"

    Rails.logger.info "Cart cleanup job completed successfully"
  rescue => e
    Rails.logger.error "Cart cleanup job failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
