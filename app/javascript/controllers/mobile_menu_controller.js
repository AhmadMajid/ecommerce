import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle("hidden")
    }
  }

  // Close menu when clicking outside
  connect() {
    console.log('Mobile menu controller connected');
    if (this.hasMenuTarget) {
      this.boundClickOutside = this.clickOutside.bind(this)
      document.addEventListener("click", this.boundClickOutside)
    }
  }

  disconnect() {
    if (this.boundClickOutside) {
      document.removeEventListener("click", this.boundClickOutside)
    }
  }

  clickOutside(event) {
    if (this.hasMenuTarget && !this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
