// app/javascript/controllers/add_to_cart_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "quantityInput", "submitButton", "variantSelect", "priceDisplay"]
  static values = {
    productId: Number,
    variants: Array,
    inStock: Boolean
  }

  connect() {
    this.updateAvailability()
    this.updatePrice()
  }

  quantityChanged() {
    const quantity = parseInt(this.quantityInputTarget.value)
    const maxQuantity = this.getMaxQuantity()

    // Validate quantity
    if (quantity < 1) {
      this.quantityInputTarget.value = 1
    } else if (quantity > maxQuantity) {
      this.quantityInputTarget.value = maxQuantity
      this.showNotification(`Only ${maxQuantity} items available in stock`, "warning")
    }

    this.updateAvailability()
    this.updatePrice()
  }

  variantChanged() {
    this.updateAvailability()
    this.updatePrice()
  }

  increaseQuantity() {
    const current = parseInt(this.quantityInputTarget.value)
    const max = this.getMaxQuantity()

    if (current < max) {
      this.quantityInputTarget.value = current + 1
      this.quantityChanged()
    }
  }

  decreaseQuantity() {
    const current = parseInt(this.quantityInputTarget.value)

    if (current > 1) {
      this.quantityInputTarget.value = current - 1
      this.quantityChanged()
    }
  }

  async addToCart(event) {
    event.preventDefault()

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.innerHTML = `
      <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Adding...
    `

    try {
      const formData = new FormData()
      formData.append('product_id', this.productIdValue)
      formData.append('quantity', this.quantityInputTarget.value)

      if (this.hasVariantSelectTarget && this.variantSelectTarget.value) {
        formData.append('variant_id', this.variantSelectTarget.value)
      }

      const response = await fetch('/cart_items', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      const data = await response.json()

      if (data.success) {
        this.showNotification(data.message, 'success')
        this.updateCartCount(data.cart_summary.item_count)
        this.updateMiniCart()

        // Reset quantity to 1 after successful add
        this.quantityInputTarget.value = 1
      } else {
        this.showNotification(data.message, 'error')
      }
    } catch (error) {
      console.error('Add to cart error:', error)
      this.showNotification('Failed to add item to cart. Please try again.', 'error')
    } finally {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.innerHTML = `
        <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l-1 12H6L5 9z"></path>
        </svg>
        Add to Cart
      `
    }
  }

  validateForm() {
    const quantity = parseInt(this.quantityInputTarget.value)
    const maxQuantity = this.getMaxQuantity()

    if (quantity < 1 || quantity > maxQuantity) {
      this.showNotification(`Please select a quantity between 1 and ${maxQuantity}`, "error")
      return false
    }

    if (this.hasVariantSelectTarget && !this.variantSelectTarget.value) {
      this.showNotification("Please select a variant", "error")
      return false
    }

    return true
  }

  updateAvailability() {
    const quantity = parseInt(this.quantityInputTarget.value)
    const maxQuantity = this.getMaxQuantity()
    const inStock = maxQuantity > 0

    this.submitButtonTarget.disabled = !inStock || quantity > maxQuantity

    if (!inStock) {
      this.submitButtonTarget.textContent = "Out of Stock"
      this.submitButtonTarget.classList.add("bg-gray-400", "cursor-not-allowed")
      this.submitButtonTarget.classList.remove("bg-indigo-600", "hover:bg-indigo-700")
    } else {
      this.submitButtonTarget.textContent = "Add to Cart"
      this.submitButtonTarget.classList.remove("bg-gray-400", "cursor-not-allowed")
      this.submitButtonTarget.classList.add("bg-indigo-600", "hover:bg-indigo-700")
    }
  }

  updatePrice() {
    if (!this.hasPriceDisplayTarget) return

    const quantity = parseInt(this.quantityInputTarget.value) || 1
    let price = this.getSelectedVariantPrice()

    const totalPrice = price * quantity
    this.priceDisplayTarget.textContent = this.formatCurrency(totalPrice)
  }

  getMaxQuantity() {
    if (this.hasVariantSelectTarget && this.variantSelectTarget.value) {
      const variant = this.variantsValue.find(v => v.id == this.variantSelectTarget.value)
      return variant ? variant.stock_quantity : 0
    }

    // Return the base product stock if no variants
    return this.element.dataset.stockQuantity ? parseInt(this.element.dataset.stockQuantity) : 0
  }

  getSelectedVariantPrice() {
    if (this.hasVariantSelectTarget && this.variantSelectTarget.value) {
      const variant = this.variantsValue.find(v => v.id == this.variantSelectTarget.value)
      return variant ? parseFloat(variant.price) : 0
    }

    // Return base product price if no variants
    const basePrice = this.element.dataset.basePrice
    return basePrice ? parseFloat(basePrice) : 0
  }

  setLoading(loading) {
    if (loading) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.innerHTML = `
        <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        Adding...
      `
    } else {
      this.updateAvailability() // This will reset the button text and state
    }
  }

  showNotification(message, type = "info") {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg transform transition-all duration-300 translate-x-full`

    // Style based on type
    switch(type) {
      case "success":
        notification.classList.add("bg-green-500", "text-white")
        break
      case "error":
        notification.classList.add("bg-red-500", "text-white")
        break
      case "warning":
        notification.classList.add("bg-yellow-500", "text-white")
        break
      default:
        notification.classList.add("bg-blue-500", "text-white")
    }

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
      notification.classList.remove("translate-x-full")
    }, 100)

    // Auto remove after 5 seconds
    setTimeout(() => {
      notification.classList.add("translate-x-full")
      setTimeout(() => notification.remove(), 300)
    }, 5000)
  }

  updateCartCount(count) {
    const cartCountElements = document.querySelectorAll('[data-cart-count]')
    cartCountElements.forEach(element => {
      element.textContent = count
      if (count > 0) {
        element.classList.remove('hidden')
      }
    })
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }
}
