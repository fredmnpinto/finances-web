# Bulk Update Redirect Fix - Tasks

## Task List

- [ ] T001 - Add resetToolbar() method to TransactionBulkController
- [ ] T002 - Update bulkUpdateSelected to call resetToolbar() on success
- [ ] T003 - Update bulkUpdateSelected to call window.location.reload() on success
- [ ] T004 - Update bulkUpdateSelected to reset toolbar on error
- [ ] T005 - Update deleteSelected to call resetToolbar() on success
- [ ] T006 - Update deleteSelected to call window.location.reload() on success
- [ ] T007 - Update deleteSelected to reset toolbar on error

## Dependencies

- T001 must complete before T002, T003, T004, T005, T006, T007
- T002 and T003 can run in parallel (both modify bulkUpdateSelected)
- T005 and T006 can run in parallel (both modify deleteSelected)

## Effort Estimate

- T001: [Small] - Adding resetToolbar() method is ~30 lines of code
- T002: [Small] - Adding resetToolbar() call after success check
- T003: [Small] - Adding window.location.reload() call after success check
- T004: [Small] - Adding resetToolbar() call in catch block
- T005: [Small] - Adding resetToolbar() call after success check
- T006: [Small] - Adding window.location.reload() call after success check
- T007: [Small] - Adding resetToolbar() call in catch block

## Detailed Task Specifications

### T001 - Add resetToolbar() method

**File:** `app/javascript/controllers/transaction_bulk_controller.js`

**Location:** Add after the `updateToolbar()` method (after line ~114)

**Implementation:**
```javascript
resetToolbar() {
  // Clear selectedIds Set
  this.selectedIds.clear()

  // Uncheck all checkboxes and remove highlights from rows
  this.rowTargets.forEach((row) => {
    row.classList.remove("bg-blue-50")
    const checkbox = row.querySelector('input[type="checkbox"]')
    if (checkbox) checkbox.checked = false
  })

  // Hide toolbar
  this.toolbarTarget.classList.add("hidden")

  // Reset selectAll checkbox
  this.selectAllTarget.checked = false

  // Update count display
  this.countTarget.textContent = "0"
}
```

**Verification:**
- Method clears selectedIds (Set is empty after call)
- All checkboxes unchecked after call
- All row backgrounds removed after call
- Toolbar hidden after call
- SelectAll checkbox unchecked after call
- Count displays "0" after call

---

### T002 - Update bulkUpdateSelected success handler

**File:** `app/javascript/controllers/transaction_bulk_controller.js`

**Location:** In `bulkUpdateSelected()` method, inside the `.then(response => {})` block

**Change:** Add `this.resetToolbar()` call when response is ok

**Current code (line 155-159):**
```javascript
}).then(response => {
  if (response.ok) {
    // Successful non-redirect response - handled
  }
  // For redirect responses, browser handles automatically
})
```

**Updated code:**
```javascript
}).then(response => {
  if (response.ok || response.redirected) {
    this.resetToolbar()
  }
})
```

**Note:** T003 adds window.location.reload() after resetToolbar().

---

### T003 - Add window.location.reload() to bulkUpdateSelected

**File:** `app/javascript/controllers/transaction_bulk_controller.js`

**Location:** In `bulkUpdateSelected()` method, same as T002

**Change:** Add `window.location.reload()` after resetToolbar() to show flash notice and refresh table

**Implementation:**
```javascript
}).then(response => {
  if (response.ok || response.redirected) {
    this.resetToolbar()
    window.location.reload()  // Reload to show flash notice and updated categories
  }
})
```

**Verification:**
- After successful bulk update, page reloads
- Flash notice is displayed after reload
- Table shows updated categories after reload

---

### T004 - Update bulkUpdateSelected error handler

**File:** `app/javascript/controllers/transaction_bulk_controller.js`

**Location:** In `bulkUpdateSelected()` method, inside the `.catch(() => {})` block

**Change:** Add `this.resetToolbar()` call in catch block to ensure toolbar state is cleaned up on error

**Current code (line 160-162):**
```javascript
}).catch(() => {
  alert("Failed to update transactions")
})
```

**Updated code:**
```javascript
}).catch(() => {
  this.resetToolbar()
  alert("Failed to update transactions")
})
```

**Verification:**
- On error, toolbar is hidden
- On error, all checkboxes are unchecked
- On error, count displays "0"

---

### T005 - Update deleteSelected success handler

**File:** `app/javascript/controllers/transaction_bulk_controller.js`

**Location:** In `deleteSelected()` method, inside the `.then(response => {})` block

**Change:** Add `this.resetToolbar()` call when response is ok

**Current code (line 190-194):**
```javascript
}).then(response => {
  if (response.ok) {
    // Successful non-redirect response - handled
  }
  // For redirect responses, browser handles automatically
})
```

**Updated code:**
```javascript
}).then(response => {
  if (response.ok || response.redirected) {
    this.resetToolbar()
  }
})
```

**Note:** deleteSelected gets its reload from T006.

---

### T006 - Add window.location.reload() to deleteSelected

**File:** `app/javascript/controllers/transaction_bulk_controller.js`

**Location:** In `deleteSelected()` method, same as T005

**Change:** Add `window.location.reload()` after resetToolbar() to show flash notice and refresh table

**Implementation:**
```javascript
}).then(response => {
  if (response.ok || response.redirected) {
    this.resetToolbar()
    window.location.reload()  // Reload to show flash notice and updated table
  }
})
```

**Verification:**
- After successful delete, page reloads
- Flash notice is displayed after reload
- Deleted rows removed from table after reload

---

### T007 - Update deleteSelected error handler

**File:** `app/javascript/controllers/transaction_bulk_controller.js`

**Location:** In `deleteSelected()` method, inside the `.catch(() => {})` block

**Change:** Add `this.resetToolbar()` call in catch block to ensure toolbar state is cleaned up on error

**Current code (line 195-200):**
```javascript
}).catch(() => {
  // Restore button state on error
  deleteButton.disabled = false
  deleteButton.textContent = originalText
  alert("Failed to delete transactions")
})
```

**Updated code:**
```javascript
}).catch(() => {
  this.resetToolbar()
  // Restore button state on error
  deleteButton.disabled = false
  deleteButton.textContent = originalText
  alert("Failed to delete transactions")
})
```

**Verification:**
- On error, toolbar is hidden
- On error, all checkboxes are unchecked
- On error, button text is restored
- On error, error alert is shown

---

## Testing Checklist

After implementing all tasks, verify:

- [ ] Bulk category update shows flash notice after success (T003 + T006)
- [ ] Toolbar is hidden after successful bulk update (T002 + T005)
- [ ] Toolbar is hidden after failed bulk update (T004 + T007)
- [ ] Checkboxes are unchecked after bulk operation (T001 called in T002/T005)
- [ ] Row highlights removed after bulk operation (T001 called in T002/T005)
- [ ] Count displays "0" after bulk operation (T001 called in T002/T005)
- [ ] Table shows updated categories after reload (T003 + T006)
- [ ] Delete shows confirmation dialog (existing behavior)
- [ ] Delete shows error alert on failure (existing + T007)
- [ ] Delete button text restores on error (existing + T007)