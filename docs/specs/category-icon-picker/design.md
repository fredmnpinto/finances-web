# Category Icon Picker - Design

## Overview

Add an interactive emoji picker to replace the plain text field for category icons. Uses `emoji-picker-element` - a modern web component that provides a full-featured emoji picker with search, categories, and skin tone support.

## Architecture

### Components

1. **EmojiPickerController** (Stimulus)
   - Wraps the emoji-picker-element Picker class
   - Handles picker toggle visibility
   - Updates text field on emoji selection

2. **emoji-picker-element** (External)
   - CDN via importmap
   - Handles all emoji UI (grid, search, categories)

### File Structure

```
New: app/javascript/controllers/emoji_picker_controller.js
Modified: config/importmap.rb
Modified: app/views/categories/index.html.erb
Modified: app/views/categories/edit.html.erb
```

### Data Flow

```
User clicks toggle → EmojiPickerController#toggle() → Picker toggles
User selects emoji → picker emits "emoji" event → Update input value + button text
```

## Data Models

No changes - Category model already has `icon` string field.

## ImportMap Configuration

**`config/importmap.rb`**:
```ruby
pin "emoji-picker-element", to: "https://cdn.jsdelivr.net/npm/emoji-picker-element@^1/index.js"
```

## Controller

**`app/javascript/controllers/emoji_picker_controller.js`**:
```javascript
import { Controller } from "@hotwired/stimulus"
import { Picker } from "emoji-picker-element"

export default class extends Controller {
  static targets = ["input", "trigger"]

  connect() {
    this.picker = new Picker({ 
      emojiVersion: "15",
      previewPosition: "none",
      dynamicWidth: true
    })
    this.element.appendChild(this.picker)
    
    this.picker.addEventListener("emoji", (e) => {
      this.inputTarget.value = e.detail.emoji
      this.triggerTarget.textContent = e.detail.emoji
    })
  }

  toggle(event) {
    event.preventDefault()
    this.picker.togglePicker(this.triggerTarget)
  }
}
```

## HTML Structure

```html
<div data-controller="emoji-picker">
  <div class="flex gap-2">
    <input 
      type="text" 
      name="category[icon]" 
      data-emoji-picker-target="input"
      value="🍕">
    <button 
      type="button"
      data-action="emoji-picker#toggle"
      data-emoji-picker-target="trigger">
      🍕
    </button>
  </div>
</div>
```

## UI/UX

- Toggle button shows current emoji (or placeholder)
- Click opens picker popover anchored to button
- Picker provides: categories, search, skin tones
- Works without JS: text field editable manually

## Implementation

| Task | Description |
|------|-------------|
| Add importmap pin | emoji-picker-element CDN |
| Create controller | Stimulus controller (~30 lines) |
| Update views | Insert picker markup in both edit views |

## Tests

- Toggle opens/closes picker
- Emoji selection updates input value
- Form submits correct value

## Timeline

- Importmap: 5 min
- Controller: 15 min
- View integration: 15 min
- Test: 15 min
- **Total: ~1 hour**