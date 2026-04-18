# Category Icon Picker

## Overview

Add an interactive emoji picker widget to replace the plain text field for category icons in the create and edit forms. The picker displays a grid of common emojis that users can click to select, with manual text entry as a fallback. This solves the problem for PC users who don't have emoji keyboard input and would otherwise need to copy/paste emojis from external sources.

## User Stories

- As a user on a PC without an emoji keyboard, I want to browse and click common emojis in a grid, so that I can easily select an icon without copy/paste.
- As a user who has a specific emoji in mind, I want to still type it manually if it's not in the common grid, so that I'm not limited to the preset options.
- As a user editing an existing category, I want to see the current icon pre-selected in the picker, so that I can modify it easily.

## Acceptance Criteria

### Must Have

- [ ] Replace `text_field :icon` with emoji picker widget in both edit and create forms
- [ ] Display grid of common emojis (minimum 30 emoji options)
- [ ] Grid items are clickable; clicking inserts the emoji into the connected text field
- [ ] Clicking an emoji in the grid updates the text field value and shows preview
- [ ] Manual text entry in the field remains functional as fallback
- [ ] Current icon value pre-populates when editing an existing category
- [ ] Visual feedback on hover for grid items (scale or background change)
- [ ] Forms remain functional without JavaScript (manual text entry works)

### Should Have

- [ ] Selected emoji in grid shows visual highlight/ring
- [ ] Clicking outside picker closes it (if using modal/popover pattern)
- [ ] Smooth animation when picker opens/closes

### Won't Have

- [ ] Search/filter functionality within the picker
- [ ] Category-specific emoji filtering (e.g., only food emojis for food categories)
- [ ] Custom emoji uploads
- [ ] Recent/frequently used emoji section
- [ ] Integration with operating system emoji picker

## UI Requirements

### Emoji Grid

- **Layout**: CSS Grid, 6-8 columns, responsive
- **Cell size**: Minimum 36x36px for touch targets
- **Emoji size**: ~24px font size within cells
- **Appearance**: Light background, subtle border, rounded corners

### Interaction

- **Hover state**: Background highlight or slight scale transform
- **Selected state**: Ring/outline around currently selected emoji
- **Click behavior**: Updates underlying text field, closes picker (if popover)

### Integration with Existing Forms

- Use existing Tailwind classes from the forms
- Maintain current layout (icon field paired with color picker in 2-column grid)
- Preserve existing labels, placeholders, and validation states

## Edge Cases

- **No emoji selected**: Show placeholder text (e.g., "Select emoji") or empty
- **Emoji not in grid**: User types manually; no synchronization with grid highlight needed
- **Invalid emoji pasted**: Allow any text input; no validation of emoji validity
- **Form loads with existing category**: Pre-populate text field; don't auto-open picker
- **Touch device users**: Grid items should have adequate touch targets (min 44px recommended)
- **JavaScript disabled**: Falls back to plain text field (native browser behavior)

## Dependencies

- No new gems required
- No database schema changes
- No API route changes
- No new model validations needed

## Technical Notes

### Emoji List

Include common category-relevant emojis:

```
Food/Drink: 🍕 🍔 🍟 🌮 🍣 🍜 ☕ 🍺 🍷 🧁
Shopping: 🛒 👗 👕 👟 💄 💍
Transport: 🚗 🚌 🚆 ✈️ ⛽
Home: 🏠 🛏️ 🛁 🚽 🧹 🔧
Health: 💊 🏥 💉 🦷
Finance: 💰 💳 📈 📉
Entertainment: 🎬 🎮 🎵 📱
Travel: ✈️ 🏖️ 🏔️ 🎒
Animals: 🐕 🐈 🐦
Nature: 🌸 🌳 🍂 ❄️ ☀️
Misc: ⭐ ❤️ 🎯 📌 ⚙️
```

### Implementation Approach

1. Create Stimulus controller for emoji picker behavior
2. Use native `<button>` elements for grid items (accessibility)
3. Store emoji list in JavaScript constants or data attributes
4. Connect to existing text field via Stimulus actions
5. Apply Tailwind classes consistent with existing form styling