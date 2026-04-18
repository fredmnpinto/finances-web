# Transactions Delete - Tasks

## Task List

- [ ] T001 - Remove inline JavaScript block (lines 214-246) from index.html.erb
- [ ] T002 - Add dedicated delete form with DELETE method in index.html.erb (replacing shared bulk form for delete action)
- [ ] T003 - Rewrite transaction_bulk_controller.js: Add CSRF token helper method
- [ ] T004 - Rewrite transaction_bulk_controller.js: Implement deleteSelected() with fetch DELETE
- [ ] T005 - Rewrite transaction_bulk_controller.js: Add loading state management during delete
- [ ] T006 - Rewrite transaction_bulk_controller.js: Add error handling with toast notification
- [ ] T007 - Rewrite transaction_bulk_controller.js: Add keyboard shortcut (Delete key) support

## Dependencies

- T001 must complete before T007 (inline JS removal is prerequisite for clean keyboard handling)
- T002 must complete before T004 (need dedicated form for fetch-based delete)
- T003 must complete before T004 (CSRF helper needed for fetch request)
- [Parallels] T004, T005, T006 can run in parallel (all part of deleteSelected rewrite)

## Effort Estimate

- T001: [Small] - Remove 33 lines of inline JS
- T002: [Small] - Add 6 lines of dedicated form
- T003: [Small] - Add ~5 lines for CSRF helper
- T004: [Medium] - Implement deleteSelected with fetch (~30 lines)
- T005: [Small] - Add ~8 lines for loading state
- T006: [Small] - Add ~10 lines for toast error
- T007: [Small] - Add ~10 lines for keyboard listener

## Notes

- Backend route `DELETE /transactions/bulk_destroy` already exists
- Transaction selection infrastructure (checkboxes, toolbar) already implemented
- Shared bulk form (lines 115-123) continues to handle update/confirm via PATCH
- Only delete flow is being rewritten to use fetch DELETE