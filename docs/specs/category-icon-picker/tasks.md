# Category Icon Picker - Tasks

## Task List

- [X] T001 - Add importmap pin for emoji-picker-element in config/importmap.rb
- [X] T002 - Create EmojiPickerController in app/javascript/controllers/emoji_picker_controller.js
- [X] T003 - Replace icon text_field with emoji picker markup in app/views/categories/index.html.erb
- [X] T004 - Replace icon text_field with emoji picker markup in app/views/categories/edit.html.erb
- [ ] T005 - Test emoji picker functionality in browser

## Dependencies

- T001 must complete before T002
- T002 must complete before T003 and T004
- T003 and T004 can run in parallel
- T005 depends on T003 and T004

## Effort Estimate

- T001: [Small] - 5 min
- T002: [Small] - 15 min
- T003: [Small] - 10 min
- T004: [Small] - 10 min
- T005: [Small] - 15 min

## Task Details

### T001 - Add importmap pin for emoji-picker-element

Add pin for emoji-picker-element CDN in config/importmap.rb:
```ruby
pin "emoji-picker-element", to: "https://cdn.jsdelivr.net/npm/emoji-picker-element@^1/index.js"
```

### T002 - Create EmojiPickerController

Create Stimulus controller at `app/javascript/controllers/emoji_picker_controller.js`:
- Import Controller from @hotwired/stimulus
- Import Picker from emoji-picker-element
- Define static targets for input and trigger
- Initialize picker in connect() lifecycle
- Listen for "emoji" event to update input and button text
- Implement toggle() action for button click

### T003 - Update categories index view

In `app/views/categories/index.html.erb` (lines 51-54):
- Replace existing text_field with emoji picker markup
- Wrap in div with data-controller="emoji-picker"
- Include input target and trigger button
- Pre-populate with existing category icon value

### T004 - Update categories edit view

In `app/views/categories/edit.html.erb` (lines 24-27):
- Replace existing text_field with emoji picker markup
- Wrap in div with data-controller="emoji-picker"
- Include input target and trigger button
- Pre-populate with existing category icon value

### T005 - Test in browser

Verify in browser:
- Emoji picker opens when toggle button clicked
- Clicking emoji updates input value and shows in button
- Form submits correct emoji value
- Manual text entry works as fallback
- Pre-population works when editing existing category
- No-JS fallback: plain text field remains editable