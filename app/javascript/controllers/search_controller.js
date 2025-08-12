// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "clear"]
  static values = {
    url: String,
    minLength: Number
  }

  connect() {
    this.timeout = null
    this.minLengthValue = this.minLengthValue || 2
  }

  search() {
    const query = this.inputTarget.value.trim()

    // Clear previous timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Show/hide clear button
    if (query.length > 0) {
      this.clearTarget.classList.remove('hidden')
    } else {
      this.clearTarget.classList.add('hidden')
    }

    // Don't search if query is too short
    if (query.length < this.minLengthValue) {
      this.hideResults()
      return
    }

    // Debounce the search
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const url = `${this.urlValue}?search=${encodeURIComponent(query)}&format=json`

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.displayResults(data.products)
      } else {
        this.hideResults()
      }
    } catch (error) {
      console.error('Search error:', error)
      this.hideResults()
    }
  }

  displayResults(products) {
    if (!this.hasResultsTarget || products.length === 0) {
      this.hideResults()
      return
    }

    // Build results HTML
    const resultsHTML = products.map(product => `
      <a href="/products/${product.slug}" class="flex items-center p-3 hover:bg-gray-50 transition-colors">
        <div class="flex-shrink-0 w-12 h-12 bg-gray-200 rounded-lg overflow-hidden mr-3">
          ${product.image_url ?
            `<img src="${product.image_url}" alt="${product.name}" class="w-full h-full object-cover">` :
            `<div class="w-full h-full flex items-center justify-center">
              <svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
              </svg>
            </div>`
          }
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 truncate">${product.name}</p>
          <p class="text-sm text-gray-500 truncate">${product.category_name || ''}</p>
          <p class="text-sm font-medium text-indigo-600">$${product.price}</p>
        </div>
      </a>
    `).join('')

    this.resultsTarget.innerHTML = resultsHTML
    this.showResults()
  }

  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove('hidden')
    }
  }

  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add('hidden')
    }
  }

  clear() {
    this.inputTarget.value = ''
    this.clearTarget.classList.add('hidden')
    this.hideResults()
    this.inputTarget.focus()
  }

  // Hide results when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // Show results when focusing input (if there's content)
  focus() {
    const query = this.inputTarget.value.trim()
    if (query.length >= this.minLengthValue && this.hasResultsTarget && this.resultsTarget.innerHTML.trim()) {
      this.showResults()
    }
  }

  // Handle keyboard navigation
  keydown(event) {
    if (!this.hasResultsTarget || this.resultsTarget.classList.contains('hidden')) {
      return
    }

    const links = this.resultsTarget.querySelectorAll('a')
    const currentIndex = Array.from(links).findIndex(link => link.classList.contains('bg-gray-100'))

    switch(event.key) {
      case 'ArrowDown':
        event.preventDefault()
        const nextIndex = currentIndex < links.length - 1 ? currentIndex + 1 : 0
        this.highlightResult(links, nextIndex)
        break

      case 'ArrowUp':
        event.preventDefault()
        const prevIndex = currentIndex > 0 ? currentIndex - 1 : links.length - 1
        this.highlightResult(links, prevIndex)
        break

      case 'Enter':
        if (currentIndex >= 0) {
          event.preventDefault()
          links[currentIndex].click()
        }
        break

      case 'Escape':
        this.hideResults()
        this.inputTarget.blur()
        break
    }
  }

  highlightResult(links, index) {
    // Remove previous highlight
    links.forEach(link => link.classList.remove('bg-gray-100'))

    // Add highlight to new result
    if (links[index]) {
      links[index].classList.add('bg-gray-100')
      links[index].scrollIntoView({ block: 'nearest' })
    }
  }
}
