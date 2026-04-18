# Transactions Delete - Design

## Overview

Implement a clean bulk delete functionality for transactions. Users select transactions via checkboxes, confirm via dialog, and delete via an API call to the existing `bulk_destroy` endpoint.

## Problem Statement

The current implementation has several issues:

1. **Wrong HTTP method**: Form uses `method: :patch` but tries to send DELETE via hidden `_method` field, which Rails ignores
2. **Fragile string manipulation**: Inline JS (lines 214-246) does unsafe string replacement for dynamic URLs
3. **Dual-layer logic**: Both Stimulus controller AND inline JS handle form submission
4. **No proper error handling**: Errors result in page reload with alert, losing selection state

## Architecture

### Components

| Component | Type | Responsibility |
|-----------|------|----------------|
| `transaction_bulk_controller.js` | Stimulus Controller | Single source of truth for selection state and delete action |
| `index.html.erb` | View | Renders table, toolbar, and delete form |
| `transactions_controller.rb` | Backend | Handles `bulk_destroy` action (already exists) |

### Data Flow

```
User clicks Delete
       ↓
Stimulus: show window.confirm()
       ↓ (user confirms)
Stimulus: fetch DELETE /transactions/bulk_destroy
       ↓
Rails: delete transactions, redirect with notice
       ↓
Turbo: page reload, notice displayed
```

### Key Differences from Current Implementation

| Aspect | Current | New |
|--------|---------|-----|
| HTTP Method | PATCH with `_method=delete` (broken) | DELETE via fetch |
| Delete Logic | Inline JS + Stimulus dual-layer | Stimulus only |
| URL Building | String replacement | Direct URL constant |
| Error Handling | Page reload, selection lost | Show error, preserve selection |
| Loading State | None | Button shows loading indicator |

## Data Models

No changes to database schema required. The `Transaction` model already exists.

## API Design

### Endpoint

```
DELETE /transactions/bulk_destroy
```

### Request

```javascript
fetch("/transactions/bulk_destroy", {
  method: "DELETE",
  headers: {
    "Content-Type": "application/x-www-form-urlencoded",
    "X-CSRF-Token": csrfToken
  },
  body: new URLSearchParams({
    transaction_ids: "1,2,3,4"
  })
})
```

### Response

**Success (302 Redirect):**
```
Location: /transactions?year=2026&month=4
Notice: "Deleted X transaction(s)"
```

**Error (422 Unprocessable Entity):**
```json
{
  "error": "Error message"
}
```

**Error (422 with Redirect):**
```
Location: /transactions?year=2026&month=4
Alert: "Error message"
```

### Request/Response Format

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `transaction_ids` | String | Yes | Comma-separated transaction IDs |

## Component Architecture

### View Structure (index.html.erb)

```erb
<div data-controller="transaction-bulk">
  <!-- Toolbar (always present in DOM, toggled via class) -->
  <div data-transaction-bulk-target="toolbar" class="hidden">
    <span data-transaction-bulk-target="count">0</span>
    <span>selected</span>
    <button data-action="click->transaction-bulk#deleteSelected">
      Delete
    </button>
  </div>

  <!-- Hidden form for delete (no _method field needed) -->
  <%= form_with url: bulk_destroy_transactions_path, 
                method: :delete, 
                id: "bulk-delete-form",
                data: { turbo: false } do %>
    <%= hidden_field_tag :transaction_ids, "" %>
  <% end %>

  <!-- Table -->
  <table>
    <thead>
      <th>
        <input type="checkbox" 
               data-transaction-bulk-target="selectAll"
               data-action="change->transaction-bulk#toggleSelectAll">
      </th>
      ...
    </thead>
    <tbody>
      <tr data-transaction-id="<%= tx.id %>"
          data-transaction-bulk-target="row"
          data-action="click->transaction-bulk#toggleSelect">
        <td>
          <input type="checkbox"
                 data-action="click->transaction-bulk#toggleCheckbox">
        </td>
        ...
      </tr>
    </tbody>
  </table>
</div>
```

### Stimulus Controller (transaction_bulk_controller.js)

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "toolbar", "count", "selectAll"]

  connect() {
    this.selectedIds = new Set()
    this.lastSelectedIndex = null
  }

  toggleSelect(event) {
    // Handle row click with shift+click range selection
  }

  toggleCheckbox(event) {
    // Handle checkbox click directly
  }

  toggleSelectAll(event) {
    // Select/deselect all rows
  }

  async deleteSelected() {
    if (this.selectedIds.size === 0) return
    
    const count = this.selectedIds.size
    if (!confirm(`Delete ${count} transaction${count > 1 ? 's' : ''}?`)) return

    // Show loading state
    const deleteButton = this.element.querySelector('[data-action*="deleteSelected"]')
    deleteButton.disabled = true
    deleteButton.dataset.originalText = deleteButton.textContent
    deleteButton.textContent = 'Deleting...'

    try {
      const csrfToken = document.querySelector('[name="csrf-token"]').content
      const response = await fetch("/transactions/bulk_destroy", {
        method: "DELETE",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": csrfToken
        },
        body: new URLSearchParams({
          transaction_ids: Array.from(this.selectedIds).join(",")
        })
      })

      if (response.redirected) {
        // Success - let Turbo handle redirect
        window.location.href = response.url
      } else if (!response.ok) {
        const data = await response.json().catch(() => ({}))
        this.showError(data.error || "Failed to delete transactions")
      }
    } catch (error) {
      this.showError("Network error. Please try again.")
    } finally {
      deleteButton.disabled = false
      deleteButton.textContent = deleteButton.dataset.originalText
    }
  }

  showError(message) {
    // Show error message (could use a toast, alert div, or window.alert)
    const errorDiv = document.createElement('div')
    errorDiv.className = 'fixed top-4 right-4 bg-red-500 text-white px-4 py-2 rounded-lg shadow-lg'
    errorDiv.textContent = message
    document.body.appendChild(errorDiv)
    setTimeout(() => errorDiv.remove(), 3000)
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

  // Keyboard shortcut
  handleKeydown(event) {
    if (event.key === "Delete" && this.selectedIds.size > 0) {
      this.deleteSelected()
    }
  }
}
```

## Error Handling

### Error Scenarios

| Scenario | Behavior | Selection Preserved |
|----------|----------|---------------------|
| Network failure | Show error message, re-enable button | Yes |
| Server returns 4xx | Show error from response, re-enable button | Yes |
| Server returns 5xx | Show generic error message, re-enable button | Yes |
| User cancels confirm | Close dialog, no action | Yes |

### Error Display

Use a dismissible toast notification at the top-right of the viewport:
- Auto-dismiss after 3 seconds
- Red background for errors
- Appears above all other content

## UI/UX

### Toolbar Visibility

| State | Toolbar | Count |
|-------|---------|-------|
| No selections | Hidden | - |
| 1+ selections | Visible | "N selected" |

### Selected Row Highlight

Add `bg-blue-50` class to selected rows (already implemented).

### Loading State

During delete request:
- Delete button shows "Deleting..."
- Delete button is disabled
- Other buttons remain enabled

### Keyboard Shortcut

| Key | Action | Requirement |
|-----|--------|-------------|
| Delete | Trigger deleteSelected() | At least 1 row selected |

## Changes Required

### 1. Remove Inline JS

Delete lines 214-246 from `index.html.erb`:
```erb
<!-- DELETE THIS ENTIRE BLOCK -->
<script>
document.addEventListener("turbo:load", function() {
  // ... fragile string manipulation
});
</script>
```

### 2. Update Form in View

Replace the shared bulk form with a dedicated delete form:

```erb
<%# New dedicated delete form - no _method field needed %>
<%= form_with url: bulk_destroy_transactions_path, 
              method: :delete, 
              id: "bulk-delete-form",
              data: { turbo: false } do %>
  <%= hidden_field_tag :transaction_ids, "" %>
<% end %>
```

Note: The existing shared form for bulk_update and confirm can remain with its current PATCH method.

### 3. Refactor Stimulus Controller

Rewrite `transaction_bulk_controller.js` to:
1. Use native fetch for delete
2. Remove dual-layer form submission logic
3. Add loading state management
4. Add error handling with toast notifications
5. Add keyboard shortcut support

### 4. Backend Changes (Optional Enhancement)

To support JSON error responses:

```ruby
def bulk_destroy
  transaction_ids = params[:transaction_ids].presence || []

  if transaction_ids.blank?
    respond_to do |format|
      format.html { redirect_to transactions_path(return_params), alert: "No transactions selected" }
      format.json { render json: { error: "No transactions selected" }, status: :unprocessable_entity }
    end
    return
  end

  # ... existing logic ...
end
```

## Testing Strategy

### Unit Tests (Stimulus)

```javascript
// transaction_bulk_controller.test.js
describe("deleteSelected", () => {
  it("shows confirm dialog with correct count");
  it("makes DELETE request with comma-separated IDs");
  it("shows loading state during request");
  it("preserves selection on error");
  it("does nothing when no rows selected");
});
```

### Integration Tests

- Select rows and delete via toolbar
- Verify DELETE request to correct endpoint
- Verify selection preserved on error
- Verify keyboard shortcut works

## Migration Path

1. **Phase 1**: Add dedicated delete form (no _method field)
2. **Phase 2**: Rewrite Stimulus controller with fetch
3. **Phase 3**: Remove inline JS
4. **Phase 4**: Add loading states and error handling
5. **Phase 5**: Add keyboard shortcut
