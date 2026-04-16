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

    // T007: Add Delete key keyboard shortcut
    document.addEventListener("keydown", (e) => {
      if (e.key === "Delete" && !this.toolbarTarget.classList.contains("hidden")) {
        this.deleteSelected()
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
    const count = this.selectedIds.size
    if (count === 0) return

    if (count === 1) {
      // Single selection: use the individual confirm endpoint
      const id = Array.from(this.selectedIds)[0]
      window.location.href = `/transactions/${id}/confirm_category?return_params=${encodeURIComponent(window.location.search)}`
    } else {
      // Multiple: use bulk update with suggested category
      this.bulkUpdateSelected("suggested")
    }
  }

  bulkUpdateSelected(categoryOverride = null) {
    const category = categoryOverride || document.getElementById("bulk-category-select").value
    if (!category) return

    const ids = Array.from(this.selectedIds).join(",")
    const token = document.querySelector('meta[name="csrf-token"]').content
    const returnParams = encodeURIComponent(window.location.search)

    fetch("/transactions/bulk_update_categories", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": token
      },
      body: `transaction_ids=${ids}&category_id=${category}&return_params=${returnParams}`
    }).then(response => {
      if (response.ok || response.redirected) {
        window.location.href = window.location.href
      } else {
        alert("Failed to update transactions")
      }
    }).catch(() => {
      alert("Failed to update transactions")
    })
  }

  // T004: Rewrite deleteSelected() with fetch DELETE
  deleteSelected() {
    const count = this.selectedIds.size
    if (count === 0) return

    // Add confirmation dialog (REQUIRED BY SPEC)
    if (!confirm(`Delete ${count} transaction${count > 1 ? 's' : ''}?`)) return

    // T005: Add loading state on Delete button
    const deleteButton = this.toolbarTarget.querySelector('button[data-action*="deleteSelected"]')
    const originalText = deleteButton.textContent
    deleteButton.disabled = true
    deleteButton.textContent = "Deleting..."

    const ids = Array.from(this.selectedIds).join(",")
    const token = document.querySelector('meta[name="csrf-token"]').content

    // T006: Add error handling
    fetch("/transactions/bulk_destroy", {
      method: "DELETE",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": token
      },
      body: `transaction_ids=${ids}`
    }).then(response => {
      if (response.ok || response.redirected) {
        window.location.href = window.location.href
      } else {
        // Restore button state on error
        deleteButton.disabled = false
        deleteButton.textContent = originalText
        alert("Failed to delete transactions")
      }
    }).catch(() => {
      // Restore button state on error
      deleteButton.disabled = false
      deleteButton.textContent = originalText
      alert("Failed to delete transactions")
    })
  }
}
