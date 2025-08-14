# Checkout Coupon Functionality

## Overview
Users can now apply and remove coupons during the checkout process, in addition to applying them in the cart.

## Features
- **Apply Coupons**: Add coupon codes during any step of checkout
- **Remove Coupons**: Remove applied coupons during checkout
- **Visual Feedback**: Clear display of applied coupons and discount amounts
- **Seamless Integration**: Coupon data flows from cart to checkout automatically

## User Interface
### Coupon Input Form
- Located in the order summary sidebar during checkout
- Only shows when no coupon is currently applied
- Simple text input with "Apply" button

### Applied Coupon Display
- Shows when a coupon is active
- Displays coupon code with green success styling
- Includes "Remove" link to remove the coupon

## Technical Implementation

### New Routes
```ruby
resources :checkout do
  collection do
    post :apply_coupon
    delete :remove_coupon
  end
end
```

### Controller Actions
- `apply_coupon`: Validates and applies coupon to cart, updates checkout totals
- `remove_coupon`: Removes coupon from cart, recalculates checkout totals

### View Integration
- Added coupon section to `_checkout_order_summary.html.erb` partial
- Displays between cart items and order totals
- Uses existing cart coupon system for backend processing

## Flow
1. User enters checkout process
2. Order summary shows current cart items and totals
3. If no coupon applied: Shows "Have a coupon code?" input form
4. If coupon applied: Shows "Coupon Applied: [CODE]" with remove option
5. Applying/removing coupons updates totals immediately
6. Coupon data persists through all checkout steps

## Files Modified
- `app/controllers/checkout_controller.rb` - Added coupon actions
- `config/routes.rb` - Added coupon routes
- `app/views/shared/_checkout_order_summary.html.erb` - Added coupon UI
- Backend leverages existing `Cart#apply_coupon` and `Cart#remove_coupon` methods

## Testing
Use test script: `bundle exec rails runner test_checkout_coupon_backend.rb`

## Benefits
- **User Experience**: Apply coupons at any time during checkout
- **Conversion**: Reduces cart abandonment from forgotten coupons
- **Flexibility**: Multiple opportunities to apply promotional codes
