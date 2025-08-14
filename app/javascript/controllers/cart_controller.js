import { Controller } from "@hotwired/stimulus"

console.log("Loading cart_controller.js file...")

export default class extends Controller {
  static targets = ["count", "subtotal", "tax", "shipping", "discount", "total", "itemTotal", "dropdown", "items"]
  static values = {
    productId: Number,
    inStock: Boolean,
    basePrice: Number,
    stockQuantity: Number
  }

  connect() {
    console.log("Cart controller connected!")
    console.log("Element:", this.element)
    console.log("Available values:", this.data.get("productId"), this.data.get("quantityValue"))
    console.log("Data attributes on element:", this.element.dataset)
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
    console.log("addToCart method called!", event)
    event.preventDefault()
    event.stopPropagation()

    const button = event.currentTarget
    const container = button.closest('[data-controller*="cart"]')

    console.log("Button element:", button)
    console.log("Container element:", container)

    // Get product data from data attributes
    const productId = this.productIdValue || container.dataset.cartProductIdValue
    const quantity = this.quantityValue || container.dataset.cartQuantityValue || 1

    console.log("Product ID:", productId, "Quantity:", quantity)

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
      // Create FormData with cart item data
      const formData = new FormData()
      formData.append('product_id', productId)
      formData.append('quantity', quantity)

      console.log("Sending request to /cart_items with:", { product_id: productId, quantity: quantity })

      const response = await fetch('/cart_items', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: formData
      })

      console.log("Response status:", response.status)
      console.log("Response headers:", response.headers.get('content-type'))

      if (response.ok) {
        const contentType = response.headers.get('content-type')
        if (contentType && contentType.includes('application/json')) {
          const data = await response.json()
          console.log("JSON response data:", data)
          this.handleAddSuccess(data, button)
        } else {
          // Handle redirect or HTML response
          console.log("Non-JSON response, handling as success")
          this.handleAddSuccess({ message: 'Added to cart!' }, button)
        }
      } else {
        const errorText = await response.text()
        console.log("Error response:", errorText)
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
    console.log('handleAddSuccess data:', data)

    // Extract cart count from response
    let newCount = 0
    if (data.cart_summary && data.cart_summary.item_count !== undefined) {
      newCount = data.cart_summary.item_count
    } else if (data.item_count !== undefined) {
      newCount = data.item_count
    }

    console.log('Updating cart count to:', newCount)

    // Update cart count immediately
    this.updateCartCount(newCount)

    // Show success animation
    this.showSuccessAnimation(button)

    // Show success notification
    this.showNotification('Added to cart!', 'success')

    // Update mini cart dropdown content
    this.updateMiniCart()

    // Force update cart badge from server as fallback
    setTimeout(() => this.updateCartCountFromServer(), 100)
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
    console.log('updateCartCount called with:', count)

    // Multiple strategies to find cart count elements
    const selectors = [
      '#cart-count',
      '[data-cart-count]',
      '.cart-count',
      '[data-cart-target="count"]',
      '.mini-cart-count'
    ]

    let elementsFound = 0
    selectors.forEach(selector => {
      const elements = document.querySelectorAll(selector)
      elements.forEach(el => {
        console.log(`Updating ${selector} element:`, el, 'to count:', count)
        el.textContent = count
        elementsFound++

        if (count > 0) {
          el.classList.remove('hidden')
          el.style.display = 'flex'
          el.style.visibility = 'visible'
        } else {
          el.classList.add('hidden')
          el.style.display = 'none'
        }
      })
    })

    console.log(`Total cart count elements found and updated: ${elementsFound}`)

    // Also update any cart count text in the page
    const cartCountTexts = document.querySelectorAll('.cart-item-count, [data-item-count]')
    cartCountTexts.forEach(el => {
      if (el.textContent.includes('item')) {
        el.textContent = `${count} ${count === 1 ? 'item' : 'items'}`
      } else {
        el.textContent = count
      }
    })
  }

  // Fetch cart count from server
  async updateCartCountFromServer() {
    try {
      const response = await fetch('/cart.json')
      if (response.ok) {
        const data = await response.json()
        this.updateCartCount(data.item_count || 0)
      }
    } catch (error) {
      console.error('Failed to fetch cart count:', error)
    }
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
          <i class="fas fa-shopping-cart text-3xl mb-2"></i>
          <p>Your cart is empty</p>
        </div>
      `
    }

    return items.map(item => `
      <div class="p-4 border-b border-gray-100 flex items-center space-x-3">
        <div class="flex-shrink-0 w-12 h-12 bg-gray-200 rounded-lg flex items-center justify-center">
          <i class="fas fa-image text-gray-400"></i>
        </div>
        <div class="flex-1">
          <h4 class="font-medium text-sm text-gray-900">${this.truncateText(item.product_name, 30)}</h4>
          <p class="text-sm text-gray-500">Qty: ${item.quantity} × $${item.unit_price}</p>
        </div>
        <button data-action="click->cart#removeItem"
                data-cart-item-id="${item.id}"
                class="text-red-400 hover:text-red-600 transition-colors">
          <i class="fas fa-trash text-sm"></i>
        </button>
      </div>
    `).join('')
  }

  truncateText(text, length) {
    return text.length > length ? text.substring(0, length) + '...' : text
  }

  // CART PAGE METHODS (NO CONFIRM DIALOGS!)

  // Remove item from cart - NO CONFIRMATION DIALOG
  async removeItem(event) {
    event.preventDefault()
    const cartItemId = event.currentTarget.dataset.cartItemId

    console.log('removeItem called with ID:', cartItemId)

    if (!cartItemId) {
      console.error('No cart item ID found')
      return
    }

    // Show loading state
    const button = event.currentTarget
    const originalContent = button.innerHTML || button.textContent
    button.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'
    button.disabled = true

    try {
      const response = await fetch(`/cart_items/${cartItemId}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        const data = await response.json()

        if (data.success) {
          // Remove the item row from the page
          const itemRow = button.closest('[data-cart-item-id]') || button.closest('li') || button.closest('.cart-item')
          if (itemRow) {
            itemRow.style.transition = 'opacity 0.3s ease-out'
            itemRow.style.opacity = '0'
            setTimeout(() => itemRow.remove(), 300)
          }

          // Update cart count and totals
          if (data.cart_summary) {
            this.updateCartCount(data.cart_summary.item_count || 0)
            this.updateCartSummary(data.cart_summary)
          }

          // Update mini cart
          this.updateMiniCart()

          // Show success notification
          this.showNotification(data.message || 'Item removed from cart', 'success')

          // Reload page if cart is now empty
          if (data.cart_summary && data.cart_summary.item_count === 0) {
            setTimeout(() => window.location.reload(), 500)
          }
        } else {
          throw new Error(data.message || 'Failed to remove item')
        }
      } else {
        throw new Error('Failed to remove item from cart')
      }
    } catch (error) {
      console.error('Remove item error:', error)
      this.showError(error.message || 'Failed to remove item. Please try again.')

      // Restore button
      button.innerHTML = originalContent
      button.disabled = false
    }
  }

  // Update quantity from input change
  async updateQuantityFromInput(event) {
    const input = event.currentTarget
    const cartItemId = input.dataset.cartItemId
    const newQuantity = parseInt(input.value)
    const originalQuantity = parseInt(input.dataset.originalValue)

    if (newQuantity === originalQuantity || newQuantity < 1) {
      input.value = originalQuantity
      return
    }

    await this.updateCartItemQuantity(cartItemId, newQuantity, input)
  }

  // Increase quantity
  async increaseQuantity(event) {
    const cartItemId = event.currentTarget.dataset.cartItemId
    const input = document.querySelector(`input[data-cart-item-id="${cartItemId}"]`)
    const currentQuantity = parseInt(input.value)

    await this.updateCartItemQuantity(cartItemId, currentQuantity + 1, input)
  }

  // Decrease quantity
  async decreaseQuantity(event) {
    const cartItemId = event.currentTarget.dataset.cartItemId
    const input = document.querySelector(`input[data-cart-item-id="${cartItemId}"]`)
    const currentQuantity = parseInt(input.value)

    if (currentQuantity > 1) {
      await this.updateCartItemQuantity(cartItemId, currentQuantity - 1, input)
    }
  }

  // Helper method to update cart item quantity
  async updateCartItemQuantity(cartItemId, quantity, inputElement) {
    console.log('updateCartItemQuantity:', cartItemId, quantity)

    // Show loading state on input
    const originalBackground = inputElement.style.backgroundColor
    inputElement.style.backgroundColor = '#f3f4f6'
    inputElement.disabled = true

    try {
      const formData = new FormData()
      formData.append('quantity', quantity)

      const response = await fetch(`/cart_items/${cartItemId}`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: formData
      })

      if (response.ok) {
        const data = await response.json()

        if (data.success) {
          // Update the input value
          inputElement.value = quantity
          inputElement.dataset.originalValue = quantity

          // Update cart summary
          if (data.cart_summary) {
            this.updateCartCount(data.cart_summary.item_count || 0)
            this.updateCartSummary(data.cart_summary)
          }

          // Update item total
          if (data.cart_item) {
            const itemTotalElement = document.querySelector(`[data-item-total="${cartItemId}"]`)
            if (itemTotalElement) {
              itemTotalElement.textContent = data.cart_item.formatted_total_price
            }
          }

          // Update mini cart
          this.updateMiniCart()

          this.showNotification(data.message || 'Cart updated', 'success')
        } else {
          throw new Error(data.message || 'Failed to update quantity')
        }
      } else {
        throw new Error('Failed to update cart')
      }
    } catch (error) {
      console.error('Update quantity error:', error)
      this.showError(error.message || 'Failed to update quantity. Please try again.')

      // Restore original quantity
      inputElement.value = inputElement.dataset.originalValue
    } finally {
      // Restore input state
      inputElement.style.backgroundColor = originalBackground
      inputElement.disabled = false
    }
  }

  // Apply coupon
  async applyCoupon(event) {
    event.preventDefault()

    const form = event.currentTarget
    const formData = new FormData(form)
    const submitButton = form.querySelector('input[type="submit"]')
    const originalValue = submitButton.value

    // Show loading state
    submitButton.value = 'Applying...'
    submitButton.disabled = true

    try {
      const response = await fetch(form.action, {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      const data = await response.json()

      if (data.success) {
        this.showNotification(data.message || 'Coupon applied successfully!', 'success')

        // Update cart summary
        if (data.cart_summary) {
          this.updateCartSummary(data.cart_summary)
          this.updateCartCount(data.cart_summary.item_count || 0)
        }

        // Reload the page to refresh the coupon section properly
        setTimeout(() => {
          window.location.reload()
        }, 1000) // Give time for the success message to show

        // Update mini cart
        this.updateMiniCart()
      } else {
        this.showError(data.message || 'Failed to apply coupon')
      }
    } catch (error) {
      console.error('Apply coupon error:', error)
      this.showError('Failed to apply coupon. Please try again.')
    } finally {
      // Restore button
      submitButton.value = originalValue
      submitButton.disabled = false
    }
  }

  // Remove coupon
  async removeCoupon(event) {
    event.preventDefault()

    const form = event.currentTarget
    const formData = new FormData(form)
    const submitButton = form.querySelector('input[type="submit"]')
    const originalValue = submitButton.value

    // Show loading state
    submitButton.value = 'Removing...'
    submitButton.disabled = true

    try {
      const response = await fetch(form.action, {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      const data = await response.json()

      if (data.success) {
        this.showNotification(data.message || 'Coupon removed successfully!', 'success')

        // Update cart summary instead of reloading
        if (data.cart_summary || data.cart) {
          const cartSummary = data.cart_summary || data
          this.updateCartSummary(cartSummary)
          const cartData = cartSummary.cart || cartSummary
          this.updateCartCount(cartData.item_count || 0)
        }

        // Reload the page to refresh the coupon section properly
        setTimeout(() => {
          window.location.reload()
        }, 1000) // Give time for the success message to show

        // Update mini cart
        this.updateMiniCart()
      } else {
        this.showError(data.message || 'Failed to remove coupon')
      }
    } catch (error) {
      console.error('Remove coupon error:', error)
      this.showError('Failed to remove coupon. Please try again.')
    } finally {
      // Restore button
      submitButton.value = originalValue
      submitButton.disabled = false
    }
  }

  // Update cart summary display
  updateCartSummary(summary) {
    console.log('updateCartSummary:', summary)

    // Handle nested cart data from carts_controller vs direct data from cart_items_controller
    const cartData = summary.cart || summary

    // Update individual elements if they exist
    const elements = {
      subtotal: this.hasSubtotalTarget ? this.subtotalTarget : document.querySelector('[data-cart-target="subtotal"]'),
      tax: this.hasTaxTarget ? this.taxTarget : document.querySelector('[data-cart-target="tax"]'),
      shipping: this.hasShippingTarget ? this.shippingTarget : document.querySelector('[data-cart-target="shipping"]'),
      discount: this.hasDiscountTarget ? this.discountTarget : document.querySelector('[data-cart-target="discount"]'),
      total: this.hasTotalTarget ? this.totalTarget : document.querySelector('[data-cart-target="total"]')
    }

    // Map the JavaScript keys to the actual data keys
    const keyMapping = {
      subtotal: 'subtotal',
      tax: 'tax_amount',
      shipping: 'shipping_amount',
      discount: 'discount_amount',
      total: 'total'
    }

    Object.entries(elements).forEach(([key, element]) => {
      const dataKey = keyMapping[key]
      const value = cartData[dataKey]

      if (element && value !== undefined && value !== null) {
        if (key === 'shipping' && value === 0) {
          element.textContent = 'Free'
        } else {
          // Ensure value is a number before calling toFixed
          const numericValue = typeof value === 'number' ? value : parseFloat(value)
          if (!isNaN(numericValue)) {
            element.textContent = `$${numericValue.toFixed(2)}`
          }
        }
      }
    })

    // Update cart count in header
    const cartCountElements = document.querySelectorAll('[data-cart-count]')
    cartCountElements.forEach(element => {
      const itemCount = cartData.item_count || 0
      element.textContent = itemCount
      element.style.display = itemCount > 0 ? 'flex' : 'none'
    })
  }

  // Update mini cart (refresh the mini cart content)
  async updateMiniCart() {
    try {
      const response = await fetch('/cart.json')
      if (response.ok) {
        const data = await response.json()

        // Find navbar cart dropdown and update it
        const cartDropdown = document.querySelector('#cart-items')
        if (cartDropdown) {
          cartDropdown.innerHTML = this.renderNavbarCartItems(data.items || [])
        }

        // Update cart count in navbar
        this.updateCartCount(data.item_count || 0)
      }
    } catch (error) {
      console.error('Error updating mini cart:', error)
    }
  }

  // Render cart items for navbar dropdown
  renderNavbarCartItems(items) {
    if (items.length === 0) {
      return `
        <div class="p-8 text-center text-gray-500">
          <i class="fas fa-shopping-cart text-3xl mb-2"></i>
          <p>Your cart is empty</p>
        </div>
      `
    }

    return items.map(item => `
      <div class="p-4 border-b border-gray-100 flex items-center space-x-3">
        <div class="flex-shrink-0 w-12 h-12 bg-gray-200 rounded-lg flex items-center justify-center">
          <i class="fas fa-image text-gray-400"></i>
        </div>
        <div class="flex-1">
          <h4 class="font-medium text-sm text-gray-900">${this.truncateText(item.product_name, 30)}</h4>
          <p class="text-sm text-gray-500">Qty: ${item.quantity} × $${item.unit_price.toFixed(2)}</p>
        </div>
        <button data-controller="cart"
                data-action="click->cart#removeItem"
                data-cart-item-id="${item.id}"
                class="text-red-400 hover:text-red-600 transition-colors">
          <i class="fas fa-trash text-sm"></i>
        </button>
      </div>
    `).join('')
  }

  // Show notification
  showNotification(message, type = 'info') {
    const colors = {
      'success': 'bg-green-500',
      'error': 'bg-red-500',
      'info': 'bg-blue-500'
    }

    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 ${colors[type]} text-white p-4 rounded-lg shadow-lg transform translate-x-full transition-transform duration-300`
    notification.innerHTML = `
      <div class="flex items-center">
        <span>${message}</span>
        <button class="ml-4 text-white hover:text-gray-200" onclick="this.parentElement.parentElement.remove()">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
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
      if (notification.parentElement) {
        notification.classList.add('translate-x-full')
        setTimeout(() => {
          if (notification.parentElement) {
            notification.remove()
          }
        }, 300)
      }
    }, 5000)
  }

  showError(message) {
    this.showNotification(message, 'error')
  }
}
