// app/javascript/controllers/tabs_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { defaultTab: String }

  connect() {
    this.showTab(this.defaultTabValue || this.tabTargets[0]?.dataset.tab || 'description')
  }

  switch(event) {
    event.preventDefault()
    const tabName = event.currentTarget.dataset.tab
    this.showTab(tabName)
  }

  showTab(tabName) {
    // Update tab buttons
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === tabName

      if (isActive) {
        tab.classList.remove(
          'border-transparent', 'text-gray-500', 'hover:text-gray-700', 'hover:border-gray-300'
        )
        tab.classList.add(
          'border-indigo-500', 'text-indigo-600'
        )
        tab.setAttribute('aria-selected', 'true')
      } else {
        tab.classList.add(
          'border-transparent', 'text-gray-500', 'hover:text-gray-700', 'hover:border-gray-300'
        )
        tab.classList.remove(
          'border-indigo-500', 'text-indigo-600'
        )
        tab.setAttribute('aria-selected', 'false')
      }
    })

    // Update panels
    this.panelTargets.forEach(panel => {
      const isActive = panel.dataset.tab === tabName

      if (isActive) {
        panel.classList.remove('hidden')
        panel.setAttribute('aria-hidden', 'false')

        // Add fade in animation
        panel.style.opacity = '0'
        setTimeout(() => {
          panel.style.transition = 'opacity 0.2s ease-in-out'
          panel.style.opacity = '1'
        }, 10)
      } else {
        panel.classList.add('hidden')
        panel.setAttribute('aria-hidden', 'true')
        panel.style.opacity = '0'
      }
    })

    // Update URL hash (optional)
    if (window.history && window.history.replaceState) {
      const url = new URL(window.location)
      url.hash = tabName
      window.history.replaceState({}, '', url)
    }
  }

  // Handle direct hash navigation
  hashChanged() {
    const hash = window.location.hash.slice(1)
    if (hash && this.tabTargets.some(tab => tab.dataset.tab === hash)) {
      this.showTab(hash)
    }
  }
}
