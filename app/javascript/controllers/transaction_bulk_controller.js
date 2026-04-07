import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "toolbar", "count", "selectAll"]

  connect() {
    this.selectedIds = new Set()
    this.lastSelectedIndex = null

    this.element.addEventListener("click", (e) => {
      const checkbox = e.target.closest("[data-stop-propagation]")
      if (checkbox) {
        e.stopImmediatePropagation()
      }
    })
  }

  toggleSelect(event) {
    const row = event.target.closest("tr")
    const checkbox = event.target.closest('input[type="checkbox"]')
    
    if (checkbox && !checkbox.dataset.stopPropagation) {
      const id = row.dataset.transactionId
      if (checkbox.checked) {
        this.selectedIds.add(id)
        row.classList.add("bg-blue-50")
      } else {
        this.selectedIds.delete(id)
        row.classList.remove("bg-blue-50")
      }
      this.lastSelectedIndex = this.getRowIndex(row)
      this.updateToolbar()
      return
    }

    const id = row.dataset.transactionId

    if (event.shiftKey && this.lastSelectedIndex !== null) {
      const currentIndex = this.getRowIndex(row)
      const start = Math.min(this.lastSelectedIndex, currentIndex)
      const end = Math.max(this.lastSelectedIndex, currentIndex)

      this.rowTargets.slice(start, end + 1).forEach((r) => {
        const rowId = r.dataset.transactionId
        this.selectedIds.add(rowId)
        r.classList.add("bg-blue-50")
      })
      
      this.rowTargets.slice(start, end + 1).forEach((r) => {
        const checkbox = r.querySelector('input[type="checkbox"]')
        if (checkbox) checkbox.checked = true
      })
    } else {
      if (this.selectedIds.has(id)) {
        this.selectedIds.delete(id)
        row.classList.remove("bg-blue-50")
        const cb = row.querySelector('input[type="checkbox"]')
        if (cb) cb.checked = false
      } else {
        this.selectedIds.add(id)
        row.classList.add("bg-blue-50")
        const cb = row.querySelector('input[type="checkbox"]')
        if (cb) cb.checked = true
      }
    }

    this.lastSelectedIndex = this.getRowIndex(row)
    this.updateToolbar()
  }

  toggleSelectAll(event) {
    const checkbox = event.target
    const shouldSelect = checkbox.checked
    
    if (shouldSelect) {
      this.rowTargets.forEach((row) => {
        this.selectedIds.add(row.dataset.transactionId)
        row.classList.add("bg-blue-50")
        const cb = row.querySelector('input[type="checkbox"]')
        if (cb) cb.checked = true
      })
    } else {
      this.selectedIds.clear()
      this.rowTargets.forEach((row) => {
        row.classList.remove("bg-blue-50")
        const cb = row.querySelector('input[type="checkbox"]')
        if (cb) cb.checked = false
      })
    }
    this.updateToolbar()
  }

  getRowIndex(row) {
    return this.rowTargets.indexOf(row)
  }

  updateToolbar() {
    const count = this.selectedIds.size
    this.countTarget.textContent = count

    if (count > 0) {
      this.toolbarTarget.classList.remove("hidden")
      this.selectAllTarget.checked = count === this.rowTargets.length
    } else {
      this.toolbarTarget.classList.add("hidden")
    }
  }

  confirmSelected() {
    this.submitForm("confirm")
  }

  bulkUpdateSelected() {
    const category = document.getElementById("bulk-category-select").value
    if (!category) return
    document.getElementById("bulk-category-field").value = category
    this.submitForm("bulk_update")
  }

  deleteSelected() {
    if (!confirm("Are you sure you want to delete the selected transactions?")) return
    this.submitForm("destroy")
  }

  submitForm(action) {
    const form = document.getElementById("bulk-action-form")
    document.getElementById("bulk-action-field").value = action
    form.requestSubmit()
  }
}
