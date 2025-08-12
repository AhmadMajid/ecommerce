// app/javascript/controllers/product_filters_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "results", "loading", "clearButton"]
  static values = {
    url: String,
    autoSubmit: Boolean
  }

  connect() {
    this.timeout = null
    this.updateClearButtonState()
  }

  // Handle form input changes with debouncing
  inputChanged(event) {
    if (!this.autoSubmitValue) return

    // Clear previous timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Debounce the submission
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, 500)
  }

  // Handle select changes (immediate submission)
  selectChanged(event) {
    if (this.autoSubmitValue) {
      this.submitForm()
    }
  }

  // Manual form submission
  async submit(event) {
    if (event) {
      event.preventDefault()
    }

    await this.submitForm()
  }

  async submitForm() {
    try {
      this.showLoading(true)

      const formData = new FormData(this.formTarget)
      const params = new URLSearchParams(formData)
      const url = `${this.urlValue}?${params.toString()}`

      const response = await fetch(url, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.updateResults(html)
        this.updateUrl(url)
        this.updateClearButtonState()
      } else {
        this.showError('Failed to load results. Please try again.')
      }
    } catch (error) {
      console.error('Filter error:', error)
      this.showError('An error occurred. Please try again.')
    } finally {
      this.showLoading(false)
    }
  }

  clearFilters() {
    // Reset form fields
    const formElements = this.formTarget.elements
    for (let element of formElements) {
      if (element.type === 'text' || element.type === 'number' || element.type === 'search') {
        element.value = ''
      } else if (element.type === 'select-one') {
        element.selectedIndex = 0
      } else if (element.type === 'checkbox' || element.type === 'radio') {
        element.checked = false
      }
    }

    // Submit the cleared form
    if (this.autoSubmitValue) {
      this.submitForm()
    }

    this.updateClearButtonState()
  }

  updateResults(html) {
    if (this.hasResultsTarget) {
      // Parse the HTML to extract just the results content
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      const newResults = doc.querySelector('#products-container')

      if (newResults) {
        this.resultsTarget.innerHTML = newResults.innerHTML
      } else {
        this.resultsTarget.innerHTML = html
      }

      // Scroll to results
      this.resultsTarget.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      })
    }
  }

  updateUrl(url) {
    // Update browser URL without page reload
    if (window.history && window.history.pushState) {
      window.history.pushState({}, '', url)
    }
  }

  updateClearButtonState() {
    if (!this.hasClearButtonTarget) return

    const hasFilters = this.hasActiveFilters()

    if (hasFilters) {
      this.clearButtonTarget.classList.remove('hidden')
    } else {
      this.clearButtonTarget.classList.add('hidden')
    }
  }

  hasActiveFilters() {
    const formElements = this.formTarget.elements

    for (let element of formElements) {
      if (element.name === 'sort') continue // Ignore sort field

      if (element.type === 'text' || element.type === 'number' || element.type === 'search') {
        if (element.value.trim() !== '') return true
      } else if (element.type === 'select-one') {
        if (element.selectedIndex > 0) return true
      } else if (element.type === 'checkbox' || element.type === 'radio') {
        if (element.checked) return true
      }
    }

    return false
  }

  showLoading(show) {
    if (this.hasLoadingTarget) {
      if (show) {
        this.loadingTarget.classList.remove('hidden')
      } else {
        this.loadingTarget.classList.add('hidden')
      }
    }

    // Also show loading on results container
    if (this.hasResultsTarget) {
      if (show) {
        this.resultsTarget.style.opacity = '0.5'
        this.resultsTarget.style.pointerEvents = 'none'
      } else {
        this.resultsTarget.style.opacity = '1'
        this.resultsTarget.style.pointerEvents = 'auto'
      }
    }
  }

  showError(message) {
    // Create error notification
    const notification = document.createElement('div')
    notification.className = 'fixed top-4 right-4 z-50 bg-red-500 text-white p-4 rounded-lg shadow-lg'
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

    // Auto remove after 5 seconds
    setTimeout(() => notification.remove(), 5000)
  }
}
