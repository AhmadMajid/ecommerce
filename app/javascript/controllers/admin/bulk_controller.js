import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "rowCheckbox", "selectedCount", "actionsBar", "row"]

  connect() {
    this.updateSelectedCount()
  }

  toggleAll(event) {
    const checked = event.target.checked
    this.rowCheckboxTargets.forEach(checkbox => {
      checkbox.checked = checked
      this.toggleRowSelection(checkbox.closest('[data-admin--bulk-target="row"]'), checked)
    })
    this.updateSelectedCount()
  }

  toggleRow(event) {
    const checkbox = event.target
    const row = checkbox.closest('[data-admin--bulk-target="row"]')
    this.toggleRowSelection(row, checkbox.checked)

    this.updateSelectedCount()
    this.updateSelectAllState()
  }

  toggleRowSelection(row, selected) {
    if (selected) {
      row.classList.add('bg-blue-50', 'border-blue-200')
    } else {
      row.classList.remove('bg-blue-50', 'border-blue-200')
    }
  }

  updateSelectedCount() {
    const selectedCount = this.getSelectedIds().length

    if (this.hasSelectedCountTarget) {
      this.selectedCountTarget.textContent = selectedCount
    }

    if (this.hasActionsBarTarget) {
      if (selectedCount > 0) {
        this.actionsBarTarget.style.display = 'block'
      } else {
        this.actionsBarTarget.style.display = 'none'
      }
    }
  }

  updateSelectAllState() {
    if (this.hasSelectAllTarget) {
      const total = this.rowCheckboxTargets.length
      const selected = this.getSelectedIds().length

      if (selected === 0) {
        this.selectAllTarget.checked = false
        this.selectAllTarget.indeterminate = false
      } else if (selected === total) {
        this.selectAllTarget.checked = true
        this.selectAllTarget.indeterminate = false
      } else {
        this.selectAllTarget.checked = false
        this.selectAllTarget.indeterminate = true
      }
    }
  }

  getSelectedIds() {
    return this.rowCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.value)
  }

  activateSelected() {
    this.performBulkAction('activate')
  }

  deactivateSelected() {
    this.performBulkAction('deactivate')
  }

  deleteSelected() {
    const selectedCount = this.getSelectedIds().length
    if (selectedCount === 0) return

    if (confirm(`Are you sure you want to delete ${selectedCount} item(s)? This action cannot be undone.`)) {
      this.performBulkAction('delete')
    }
  }

  showCategoryModal() {
    // This would open a modal to select a new category
    // Implementation depends on your modal system
    console.log('Show category modal for:', this.getSelectedIds())
  }

  showImportModal() {
    // This would open a modal for importing
    // Implementation depends on your modal system
    console.log('Show import modal')
  }

  async performBulkAction(action) {
    const selectedIds = this.getSelectedIds()
    if (selectedIds.length === 0) return

    const currentPath = window.location.pathname
    const url = `${currentPath}/bulk_update`

    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          ids: selectedIds,
          action: action
        })
      })

      if (response.ok) {
        // Reload the page to show updated data
        window.location.reload()
      } else {
        console.error('Bulk action failed:', response.statusText)
        alert('Action failed. Please try again.')
      }
    } catch (error) {
      console.error('Bulk action error:', error)
      alert('Action failed. Please try again.')
    }
  }
}
