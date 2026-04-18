# Transactions Delete

## Overview

Implement a clean bulk delete functionality for transactions. Users select multiple transactions via checkboxes, click Delete in the bulk toolbar, confirm via dialog, and the selected transactions are deleted via an API call to the existing `bulk_destroy` endpoint.

## User Stories

- As a user, I want to select multiple transactions by clicking checkboxes, so that I can perform bulk operations.
- As a user, I want to delete selected transactions with a single click, so that I can remove unwanted transactions quickly.
- As a user, I want to see a confirmation dialog before deletion, so that I can avoid accidentally deleting transactions.
- As a user, I want to see feedback on success or failure, so that I know the result of my action.

## Acceptance Criteria

### Must Have

- [ ] Checkbox in each transaction row for selection
- [ ] Select All checkbox in table header to toggle all selections
- [ ] Shift+click support for range selection
- [ ] Click on row toggles selection and updates checkbox state
- [ ] Bulk toolbar appears at bottom of screen when at least one transaction is selected
- [ ] Toolbar displays count of selected transactions
- [ ] Delete button in toolbar triggers confirmation dialog
- [ ] Confirmation dialog shows count of transactions to be deleted
- [ ] DELETE request to `/transactions/bulk_destroy` with `transaction_ids` as comma-separated string
- [ ] On success (2xx): page refreshes to show updated transaction list
- [ ] On error: user sees error message and selections are preserved

### Should Have

- [ ] Visual highlight on selected rows (e.g., blue background)
- [ ] Loading state on Delete button while request is in progress
- [ ] Keyboard shortcut (Delete key) triggers delete when rows are selected

### Won't Have

- [ ] Individual row delete buttons (single transaction delete)
- [ ] Undo functionality after deletion
- [ ] Turbo Streams for partial page updates (full page reload on success is acceptable)

## Edge Cases

- **No transactions selected**: Delete button should not be visible/enabled
- **All transactions selected**: Select All checkbox should appear checked
- **Deselect all after selecting**: Toolbar should hide
- **Network failure**: Show error message, preserve selection state
- **Server returns error (4xx/5xx)**: Show error message, preserve selection state
- **Empty transaction list**: Toolbar should not appear, Select All should not render
- **Rapid clicking**: Debounce delete action to prevent duplicate requests

## Dependencies

- Existing `DELETE /transactions/bulk_destroy` route (already exists)
- Existing `TransactionsController#bulk_destroy` action (already exists)
- Existing `transaction_bulk` Stimulus controller (will be rewritten)
- Existing transaction selection infrastructure (row targets, selectedIds tracking)

## Technical Notes

### API Contract

**Request:**
```
DELETE /transactions/bulk_destroy
Content-Type: application/x-www-form-urlencoded

transaction_ids=1,2,3,4
```

**Success Response (302):**
```ruby
redirect_to transactions_path(return_params), notice: "Deleted X transaction(s)"
```

**Error Response (302):**
```ruby
redirect_to transactions_path(return_params), alert: "Error message"
```

### Implementation Approach

1. Rewrite `transaction_bulk_controller.js` to be cleaner and more focused
2. Move inline JavaScript from `index.html.erb` into the Stimulus controller
3. Use native `window.confirm()` for simplicity (consistent with existing `confirm_category` pattern)
4. Use Turbo for page navigation on success (default Rails redirect behavior)
5. Handle errors gracefully by catching Turbo navigation failures
