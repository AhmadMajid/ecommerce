import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    // Close mini cart when clicking outside
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener('click', this.boundCloseOnOutsideClick)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.panelTarget.classList.contains('hidden')) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove('hidden')

    // Add click listener to close on outside click
    setTimeout(() => {
      document.addEventListener('click', this.boundCloseOnOutsideClick)
    }, 100)
  }

  close() {
    this.panelTarget.classList.add('hidden')
    document.removeEventListener('click', this.boundCloseOnOutsideClick)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
