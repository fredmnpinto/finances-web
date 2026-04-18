# Add Another Checkbox - Design

## Overview

Add an "Add another" checkbox to the manual transaction form. When checked and the transaction saves successfully, the user stays on the form page with a fresh form. When unchecked (default), redirect to the transactions list as currently implemented.

## Architecture

### Components

| Component | Responsibility |
|-----------|----------------|
| `ManualTransactionsController#create` | Handle save logic and conditional redirect |
| `app/views/manual_transactions/new.html.erb` | Form with new checkbox field |
| `Transaction` model | Already handles validation (no changes needed) |

## Data Models

No changes required. The `add_another` parameter is not persisted to the database - it only controls redirect behavior.

## API Design

### Controller Changes

**`app/controllers/manual_transactions_controller.rb`**

1. Add `:add_another` to permitted params:

```ruby
def transaction_params
  params.require(:transaction).permit(:date, :description, :amount, :balance, :category_id, :source_file, :transaction_type, :add_another)
end
```

2. Modify `create` action to check the checkbox and redirect accordingly:

```ruby
def create
  @transaction = current_user.transactions.new(transaction_params)

  if @transaction.expense?
    @transaction.amount = -@transaction.amount.abs
  end

  if @transaction.save
    if params[:transaction][:add_another] == "1"
      redirect_to new_manual_transaction_path, notice: "Transaction added successfully"
    else
      redirect_to transactions_path, notice: "Transaction added successfully"
    end
  else
    @categories = current_user.categories.order(:name).to_a
    render :new, status: :unprocessable_entity
  end
end
```

Note: The checkbox value will be `"1"` when checked, `nil` or `"0"` when unchecked.

## UI/UX

### Layout

Add the checkbox inside the form, after the category field and before the submit button area. Place it in the field section to keep all inputs together.

### Checkbox Placement

The checkbox should be added at the end of the form fields section (before the divider), positioned to align with other form controls.

### Visual Design

Use Tailwind classes matching existing patterns in the codebase:

```erb
<div class="flex items-center">
  <%= f.check_box :add_another, class: "h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" %>
  <%= f.label :add_another, "Add another", class: "ml-2 block text-sm text-gray-900" %>
</div>
```

### Styling Details

- Checkbox: `h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded` (matches existing remember_me checkbox)
- Label: `ml-2 block text-sm text-gray-900` (standard label styling)
- Wrapper: `flex items-center` (horizontal alignment)

### Location in Form

Add after the category dropdown, before the divider and submit button area:

```erb
      <div class="space-y-4">
        <!-- existing fields... -->
        <div>
          <%= f.label :category_id, "Category", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= f.collection_select :category_id, @categories, :id, :name, { include_blank: "Select a category" }, class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm" %>
        </div>
        
        <!-- NEW CHECKBOX HERE -->
        <div class="flex items-center">
          <%= f.check_box :add_another, class: "h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" %>
          <%= f.label :add_another, "Add another", class: "ml-2 block text-sm text-gray-900" %>
        </div>
      </div>

      <div class="flex items-center justify-between pt-6 mt-6 border-t border-gray-200">
```

### Success Notice

Both paths use the same notice: `"Transaction added successfully"`

## Edge Cases

1. **Checkbox checked + save fails**: Stay on form with validation errors (existing behavior)
2. **Checkbox unchecked + save fails**: Stay on form with validation errors (existing behavior)
3. **User navigates away and returns**: Form is fresh, checkbox unchecked (existing behavior)

## Testing Considerations

### Controller Tests
- Test redirect to transactions_path when checkbox unchecked
- Test redirect to new_manual_transaction_path when checkbox checked
- Test form re-render with errors when save fails (both checkbox states)

### View Tests
- Test checkbox presence in form
- Test checkbox label text
- Test default unchecked state

### Integration Tests
- Full flow: submit with checkbox checked → form resets, can add another
- Full flow: submit with checkbox unchecked → redirects to transactions list