// app/javascript/controllers/product_gallery_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mainImage", "thumbnail", "zoomContainer"]
  static values = { zoom: Boolean }

  connect() {
    this.currentImageIndex = 0
    this.images = this.thumbnailTargets.map(thumb => thumb.dataset.image)

    // Set first thumbnail as active
    if (this.thumbnailTargets.length > 0) {
      this.thumbnailTargets[0].classList.add("ring-2", "ring-indigo-500")
    }
  }

  selectImage(event) {
    const thumbnail = event.currentTarget
    const imageUrl = thumbnail.dataset.image
    const imageAlt = thumbnail.dataset.alt || "Product image"
    const index = parseInt(thumbnail.dataset.index)

    // Update main image
    this.mainImageTarget.src = imageUrl
    this.mainImageTarget.alt = imageAlt

    // Update active thumbnail
    this.thumbnailTargets.forEach(thumb => {
      thumb.classList.remove("ring-2", "ring-indigo-500")
    })
    thumbnail.classList.add("ring-2", "ring-indigo-500")

    this.currentImageIndex = index
  }

  previousImage() {
    const newIndex = this.currentImageIndex > 0 ? this.currentImageIndex - 1 : this.images.length - 1
    this.thumbnailTargets[newIndex].click()
  }

  nextImage() {
    const newIndex = this.currentImageIndex < this.images.length - 1 ? this.currentImageIndex + 1 : 0
    this.thumbnailTargets[newIndex].click()
  }

  toggleZoom() {
    if (!this.hasZoomContainerTarget) return

    if (this.zoomValue) {
      this.zoomContainerTarget.classList.add("cursor-zoom-out")
      this.mainImageTarget.classList.add("scale-150")
    } else {
      this.zoomContainerTarget.classList.remove("cursor-zoom-out")
      this.mainImageTarget.classList.remove("scale-150")
    }

    this.zoomValue = !this.zoomValue
  }

  // Keyboard navigation
  keydown(event) {
    switch(event.key) {
      case "ArrowLeft":
        event.preventDefault()
        this.previousImage()
        break
      case "ArrowRight":
        event.preventDefault()
        this.nextImage()
        break
      case "Escape":
        event.preventDefault()
        if (this.zoomValue) {
          this.toggleZoom()
        }
        break
    }
  }
}
