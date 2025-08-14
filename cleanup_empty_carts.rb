#!/usr/bin/env ruby

puts "=== Cart Cleanup Script ==="

# Find empty guest carts (no cart items)
empty_guest_carts = Cart.guest_carts
                       .joins("LEFT JOIN cart_items ON carts.id = cart_items.cart_id")
                       .where("cart_items.id IS NULL")

puts "Found #{empty_guest_carts.count} empty guest carts"

# Also find old guest carts (older than 7 days)
old_guest_carts = Cart.guest_carts.where("created_at < ?", 7.days.ago)
puts "Found #{old_guest_carts.count} old guest carts (>7 days)"

# Combine both criteria for deletion
carts_to_delete = Cart.guest_carts
                     .where(
                       "id IN (?) OR created_at < ?",
                       empty_guest_carts.pluck(:id),
                       7.days.ago
                     )

puts "Total carts to delete: #{carts_to_delete.count}"

if carts_to_delete.count > 0
  puts "Deleting carts..."
  deleted_count = carts_to_delete.delete_all
  puts "✅ Deleted #{deleted_count} carts"
else
  puts "No carts to delete"
end

puts "\n📊 Final cart counts:"
puts "Total carts: #{Cart.count}"
puts "Active carts: #{Cart.active.count}"
puts "Guest carts: #{Cart.guest_carts.count}"
puts "User carts: #{Cart.user_carts.count}"
