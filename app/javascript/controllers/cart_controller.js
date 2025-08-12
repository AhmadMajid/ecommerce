import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "subtotal", "tax", "shipping", "discount", "total", "itemTotal"]

  connect() {
    console.log("Cart controller connected")
  }

  // Increase quantity
  increaseQuantity(event) {
    const cartItemId = event.currentTarget.dataset.cartItemId
    const input = document.querySelector(`input[data-cart-item-id="${cartItemId}"]`)
    const currentQuantity = parseInt(input.value)

    this.updateQuantity(cartItemId, currentQuantity + 1)
  }

  // Decrease quantity
  decreaseQuantity(event) {
    const cartItemId = event.currentTarget.dataset.cartItemId
    const input = document.querySelector(`input[data-cart-item-id="${cartItemId}"]`)
    const currentQuantity = parseInt(input.value)

    if (currentQuantity > 1) {
      this.updateQuantity(cartItemId, currentQuantity - 1)
    }
  }

  // Update quantity from input field
  updateQuantity(event) {
    const cartItemId = event.currentTarget.dataset.cartItemId
    const newQuantity = parseInt(event.currentTarget.value)

    if (newQuantity > 0) {
      this.updateQuantity(cartItemId, newQuantity)
    }
  }

  // Remove item from cart
  removeItem(event) {
    const cartItemId = event.currentTarget.dataset.cartItemId

    if (confirm('Are you sure you want to remove this item from your cart?')) {
      this.performCartAction(`/cart_items/${cartItemId}`, 'DELETE')
    }
  }

  // Apply coupon code
  applyCoupon(event) {
    event.preventDefault()
    const form = event.currentTarget
    const formData = new FormData(form)

    fetch(form.action, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.cart) {
        this.updateCartSummary(data.cart)
        this.showNotification('Coupon applied successfully!', 'success')
      }
    })
    .catch(error => {
      console.error('Error applying coupon:', error)
      this.showNotification('Error applying coupon', 'error')
    })
  }

  // Update quantity helper
  updateQuantity(cartItemId, quantity) {
    const formData = new FormData()
    formData.append('quantity', quantity)

    this.performCartAction(`/cart_items/${cartItemId}`, 'PATCH', formData)
  }

  // Perform cart action (add, update, remove)
  performCartAction(url, method, body = null) {
    const options = {
      method: method,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    }

    if (body) {
      options.body = body
    }

    fetch(url, options)
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          if (data.cart_summary) {
            this.updateCartSummary(data.cart_summary)
          }

          if (data.cart_item) {
            this.updateCartItem(data.cart_item)
          }

          // Update mini cart
          this.updateMiniCart()

          // Show notification
          this.showNotification(data.message, 'success')

          // If item was removed, remove the row
          if (method === 'DELETE') {
            const itemRow = document.querySelector(`[data-cart-item-id="${data.cart_item?.id}"]`)
            if (itemRow) {
              itemRow.remove()
            }
          }
        } else {
          this.showNotification(data.message, 'error')
        }
      })
      .catch(error => {
        console.error('Cart action error:', error)
        this.showNotification('An error occurred. Please try again.', 'error')
      })
  }

  // Update cart summary display
  updateCartSummary(summary) {
    // Update counts
    if (this.hasCountTarget) {
      this.countTarget.textContent = summary.item_count
    }

    // Update item count in summary
    const itemCountElement = document.querySelector('[data-item-count]')
    if (itemCountElement) {
      itemCountElement.textContent = summary.item_count
    }

    // Update prices
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = summary.formatted_subtotal
    }

    if (this.hasTaxTarget) {
      this.taxTarget.textContent = summary.formatted_tax
    }

    if (this.hasShippingTarget) {
      this.shippingTarget.textContent = summary.shipping_amount > 0 ? summary.formatted_shipping : 'Free'
    }

    if (this.hasDiscountTarget && summary.discount_amount > 0) {
      this.discountTarget.textContent = `-${summary.formatted_discount}`
    }

    if (this.hasTotalTarget) {
      this.totalTarget.textContent = summary.formatted_total
    }

    // Update cart count in header
    const cartCountElements = document.querySelectorAll('[data-cart-count]')
    cartCountElements.forEach(element => {
      element.textContent = summary.item_count
      element.style.display = summary.item_count > 0 ? 'flex' : 'none'
    })
  }

  // Update individual cart item
  updateCartItem(cartItem) {
    const itemTotalElement = document.querySelector(`[data-item-total="${cartItem.id}"]`)
    if (itemTotalElement) {
      itemTotalElement.textContent = cartItem.formatted_total_price
    }

    const quantityInput = document.querySelector(`input[data-cart-item-id="${cartItem.id}"]`)
    if (quantityInput) {
      quantityInput.value = cartItem.quantity
    }
  }

  // Update mini cart (refresh the mini cart content)
  updateMiniCart() {
    fetch('/cart/mini', {
      headers: {
        'Accept': 'text/html'
      }
    })
    .then(response => response.text())
    .then(html => {
      const miniCartElement = document.querySelector('[data-controller="mini-cart"]')
      if (miniCartElement) {
        miniCartElement.outerHTML = html
      }
    })
    .catch(error => {
      console.error('Error updating mini cart:', error)
    })
  }

  // Show notification
  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-md shadow-lg max-w-sm transform transition-transform duration-300 translate-x-full ${
      type === 'success' ? 'bg-green-100 text-green-800 border border-green-200' :
      type === 'error' ? 'bg-red-100 text-red-800 border border-red-200' :
      'bg-blue-100 text-blue-800 border border-blue-200'
    }`

    notification.innerHTML = `
      <div class="flex items-center justify-between">
        <p class="text-sm font-medium">${message}</p>
        <button class="ml-3 text-current opacity-70 hover:opacity-100" onclick="this.parentElement.parentElement.remove()">
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
          </svg>
        </button>
      </div>
    `

    document.body.appendChild(notification)

    // Animate in
    setTimeout(() => {
      notification.classList.remove('translate-x-full')
    }, 100)

    // Auto remove after 5 seconds
    setTimeout(() => {
      notification.classList.add('translate-x-full')
      setTimeout(() => {
        notification.remove()
      }, 300)
    }, 5000)
  }
}
