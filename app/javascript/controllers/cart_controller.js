import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "subtotal", "tax", "shipping", "discount", "total", "itemTotal", "dropdown", "items"]
  static values = {
    productId: Number,
    inStock: Boolean,
    basePrice: Number,
    stockQuantity: Number
  }

  connect() {
    console.log("Cart controller connected")
    this.isOpen = false
    this.addTimeout = null
    this.element.addEventListener('click', (e) => e.stopPropagation())
    document.addEventListener('click', this.closeDropdown.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.closeDropdown.bind(this))
    if (this.addTimeout) clearTimeout(this.addTimeout)
  }

  // Quick add to cart for homepage
  async addToCart(event) {
    event.preventDefault()
    event.stopPropagation()

    const form = event.currentTarget
    const button = form.querySelector('button[type="submit"]')
    const productIdInput = form.querySelector('input[name="product_id"]')
    const quantityInput = form.querySelector('input[name="quantity"]')

    const productId = productIdInput ? productIdInput.value : (button.dataset.productId || this.productIdValue)
    const quantity = quantityInput ? parseInt(quantityInput.value) : 1

    if (!productId) {
      this.showError("Product not found")
      return
    }

    // Show loading state
    const originalContent = button.innerHTML
    button.innerHTML = `
      <svg class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
    `
    button.disabled = true

    try {
      const formData = new FormData(form)

      const response = await fetch('/cart_items', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: formData
      })

      if (response.ok) {
        const contentType = response.headers.get('content-type')
        if (contentType && contentType.includes('application/json')) {
          const data = await response.json()
          this.handleAddSuccess(data, button)
        } else {
          // Handle redirect or HTML response
          this.handleAddSuccess({ message: 'Added to cart!' }, button)
        }
      } else {
        const errorText = await response.text()
        this.handleAddError(errorText || 'Failed to add item to cart', button)
      }
    } catch (error) {
      console.error('Cart add error:', error)
      this.handleAddError('Network error. Please try again.', button)
    } finally {
      // Restore button
      setTimeout(() => {
        button.innerHTML = originalContent
        button.disabled = false
      }, 1000)
    }
  }

  handleAddSuccess(data, button) {
    // Update cart count
    this.updateCartCount(data.cart_count || data.item_count)

    // Show success animation
    this.showSuccessAnimation(button)

    // Show success notification
    this.showNotification('Added to cart!', 'success')

    // Update cart dropdown if open
    if (this.hasDropdownTarget && this.isOpen) {
      this.refreshCartDropdown()
    }
  }

  handleAddError(error, button) {
    this.showError(error)

    // Show error animation
    button.classList.add('animate-pulse', 'bg-red-500')
    setTimeout(() => {
      button.classList.remove('animate-pulse', 'bg-red-500')
    }, 1000)
  }

  showSuccessAnimation(button) {
    // Success animation
    button.classList.add('animate-bounce', 'bg-green-500')
    setTimeout(() => {
      button.classList.remove('animate-bounce', 'bg-green-500')
    }, 1000)
  }

  updateCartCount(count) {
    // Update cart count in header
    const cartCounts = document.querySelectorAll('#cart-count, [data-cart-count]')
    cartCounts.forEach(el => {
      el.textContent = count
      if (count > 0) {
        el.classList.remove('hidden')
      } else {
        el.classList.add('hidden')
      }
    })
  }

  closeDropdown(event) {
    if (this.hasDropdownTarget && this.isOpen && !this.element.contains(event.target)) {
      this.isOpen = false
      this.dropdownTarget.classList.add('hidden')
    }
  }

  async refreshCartDropdown() {
    if (!this.hasDropdownTarget) return

    try {
      const response = await fetch('/cart.json')
      const data = await response.json()

      // Update cart items in dropdown
      if (this.hasItemsTarget) {
        this.itemsTarget.innerHTML = this.renderCartItems(data.items || [])
      }
    } catch (error) {
      console.error('Failed to refresh cart:', error)
    }
  }

  renderCartItems(items) {
    if (items.length === 0) {
      return `
        <div class="p-8 text-center text-gray-500">
          <svg class="w-12 h-12 mx-auto mb-2 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-1.5 6M7 13l-1.5 6m0 0h9m-9 0h9"></path>
          </svg>
          <p>Your cart is empty</p>
        </div>
      `
    }

    return items.map(item => `
      <div class="p-4 border-b border-gray-100 flex items-center space-x-3">
        <div class="flex-shrink-0 w-12 h-12 bg-gray-200 rounded-lg flex items-center justify-center">
          ${item.image_url ?
            `<img src="${item.image_url}" class="w-full h-full object-cover rounded-lg" alt="${item.name}">` :
            `<svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
               <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
             </svg>`
          }
        </div>
        <div class="flex-1">
          <h4 class="font-medium text-sm text-gray-900">${this.truncateText(item.name, 30)}</h4>
          <p class="text-sm text-gray-500">Qty: ${item.quantity} × $${item.price}</p>
        </div>
        <button data-action="click->cart#removeItem"
                data-item-id="${item.id}"
                class="text-red-400 hover:text-red-600 transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
          </svg>
        </button>
      </div>
    `).join('')
  }

  truncateText(text, length) {
    return text.length > length ? text.substring(0, length) + '...' : text
  }

  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 px-6 py-3 rounded-lg font-medium shadow-lg transform translate-x-full transition-transform duration-300 ${
      type === 'success' ? 'bg-green-500 text-white' :
      type === 'error' ? 'bg-red-500 text-white' :
      'bg-blue-500 text-white'
    }`
    notification.textContent = message

    document.body.appendChild(notification)

    // Animate in
    setTimeout(() => {
      notification.classList.remove('translate-x-full')
    }, 100)

    // Remove after delay
    setTimeout(() => {
      notification.classList.add('translate-x-full')
      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 3000)
  }

  showError(message) {
    this.showNotification(message, 'error')
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
