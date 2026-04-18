# Add Another Checkbox for Manual Transaction Form

## Overview

Add an "Add another" checkbox to the manual transaction form at `/manual-transaction`. When selected and the transaction saves successfully, the user stays on the same page with a fresh form to add another transaction. When unchecked (default), the current behavior remains: redirect to `/transactions` with a success notice.

## User Stories

- As a user, I want to add multiple transactions in quick succession without navigating back to the form each time, so that I can efficiently enter several transactions.
- As a user, I want a checkbox that lets me control whether to stay on or leave the form after submission, so that I can choose the workflow that fits my needs.

## Acceptance Criteria

### Must Have

- [ ] Checkbox field labeled "Add another" added to the manual transaction form
- [ ] Checkbox is unchecked by default (preserves existing behavior)
- [ ] Checkbox placed below the form fields, above or near the submit button
- [ ] When checked AND transaction saves successfully: redirect to `/manual-transaction` with success notice, form reset (fresh Transaction model)
- [ ] When unchecked (default) AND transaction saves successfully: redirect to `/transactions` with success notice (current behavior)
- [ ] When transaction fails to save: stay on form with validation errors displayed (current behavior)
- [ ] Success notice text reflects that transaction was added successfully

### Should Have

- [ ] Checkbox uses appropriate accessibility label for screen readers
- [ ] Checkbox label positioned logically relative to the submit button

### Won't Have

- [ ] Partial page updates (Turbo Streams) - full page redirect is acceptable
- [ ] Client-side only behavior without server-side handling

## Edge Cases

- **Checkbox checked but validation fails**: Stay on form with errors (not redirect anywhere)
- **Checkbox unchecked (default) and validation fails**: Stay on form with errors (current behavior)
- **User navigates away and returns**: Checkbox should be unchecked (fresh state)
- **Browser back button after successful submission with checkbox checked**: Form should be reset, checkbox unchecked
- **Session times out during form fill**: Normal session timeout behavior (not related to this feature)

## Dependencies

- Existing `ManualTransactionsController#new` action (already creates new Transaction model)
- Existing `ManualTransactionsController#create` action (handles save logic)
- Existing form view at `app/views/manual_transactions/new.html.erb`
- Existing route `GET /manual-transaction` → `ManualTransactionsController#new`
- Existing route `POST /manual_transactions` → `ManualTransactionsController#create`

## Technical Notes

### Form Parameter Addition

The checkbox value needs to be passed to the controller. In the form:

```erb
<%= f.check_box :add_another %>
<%= f.label :add_another, "Add another" %>
```

### Controller Logic

In `ManualTransactionsController#create`, after successful save:

```ruby
if @transaction.save
  if params[:transaction][:add_another] == "1"
    redirect_to new_manual_transaction_path, notice: "Transaction added successfully"
  else
    redirect_to transactions_path, notice: "Transaction added successfully"
  end
end
```

### Parameter Whitelist

The `add_another` attribute needs to be added to the permitted params:

```ruby
def transaction_params
  params.require(:transaction).permit(:date, :description, :amount, :balance, :category_id, :source_file, :transaction_type, :add_another)
end
```

Note: `add_another` is not a database column - it only exists as a form parameter to control redirect behavior.