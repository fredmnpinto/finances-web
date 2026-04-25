# Async Category Recommender - Tasks

## Task List

- [X] T001 - Add source: parameter to CategoryRecommender#categorize
- [X] T002 - Create CategorizeTransactionJob
- [X] T003 - Create AsyncCategoryImprovement feature flag module
- [X] T004 - Update ImportTransactions to schedule job when rules return nil
- [X] T005 - Add tests for CategoryRecommender source parameter
- [X] T006 - Add tests for CategorizeTransactionJob
- [X] T007 - Add tests for ImportTransactions async behavior

## Dependencies

- T001 must complete before T002, T003, T004
- T003 must complete before T004
- T005 can run in parallel with T006
- T007 depends on T004

```
## Dependency Graph
T001 ──┬──► T002 ──► T005
       │
       ├──► T003 ──► T004 ──► T007
       │
       └──► T005
```

## Effort Estimate

- T001: [Small]
- T002: [Medium]
- T003: [Small]
- T004: [Small]
- T005: [Small]
- T006: [Medium]
- T007: [Medium]

## Task Details

### T001 - Add source: parameter to CategoryRecommender#categorize

**File:** `app/services/category_recommender.rb`

**Description:** Add `source:` keyword argument to the `categorize` method that routes to different categorization logic based on the source value:
- `:rules` - Returns result from `apply_rules` only, or nil if no match (never falls back)
- `:llm` - Returns result from Ollama only
- `:all` (default) - Falls back to LLM when rules return nil (backward compatible)

**Reference:** See design.md lines 194-206 for implementation details

---

### T002 - Create CategorizeTransactionJob

**File:** `app/jobs/categorize_transaction_job.rb`

**Description:** Create a new ActiveJob that:
- Receives `transaction_id` and `source: :llm`
- Finds the transaction, skips if user already has a category set (`category_id` present)
- Calls `CategoryRecommender.categorize` with source: :llm
- Updates `suggested_category` on success
- Has retry logic: 3 attempts with exponential backoff
- Discards gracefully if transaction is deleted (ActiveJob::DeserializationError)
- Logs all operations

**Reference:** See design.md lines 213-247 for implementation details

---

### T003 - Create AsyncCategoryImprovement feature flag module

**File:** `app/services/async_category_improvement.rb`

**Description:** Create a simple module that exposes:
- `AsyncCategoryImprovement.enabled?` - Returns true if ENV["ASYNC_CATEGORY_ENABLED"] != "false", defaults to true

**Reference:** See design.md lines 293-298 for implementation details

---

### T004 - Update ImportTransactions to schedule job when rules return nil

**File:** `app/services/import_transactions.rb`

**Description:** Modify the transaction import flow to:
- Call `categorizer.categorize` with `source: :rules` first
- If rules match (result present), use the suggested category
- If rules return nil AND `AsyncCategoryImprovement.enabled?`, schedule `CategorizeTransactionJob.perform_later(transaction.id, source: :llm)`
- Import continues immediately without waiting for the job

**Reference:** See design.md lines 254-286 for implementation details

---

### T005 - Add tests for CategoryRecommender source parameter

**File:** `spec/services/category_recommender_spec.rb`

**Description:** Add tests verifying:
- `source: :rules` returns match when keywords present in description
- `source: :rules` returns nil when no rules match (never returns fallback)
- `source: :llm` calls OllamaClient and returns result
- `source: :all` (default) falls back to LLM when rules return nil
- Default behavior is backward compatible

---

### T006 - Add tests for CategorizeTransactionJob

**File:** `spec/jobs/categorize_transaction_job_spec.rb` (create new)

**Description:** Create spec for the job verifying:
- Updates transaction's `suggested_category` when found and uncategorized
- Skips when transaction has user-selected category (`category_id` present)
- Handles missing transaction gracefully (discards without error)
- Handles deleted transaction (ActiveJob::DeserializationError)
- Retries on transient failures (3 attempts)
- Logs success and failure appropriately

---

### T007 - Add tests for ImportTransactions async behavior

**File:** `spec/services/import_transactions_spec.rb`

**Description:** Add tests verifying:
- Schedules CategorizeTransactionJob when rules return nil and feature flag enabled
- Does NOT schedule job when rules match (immediate categorization)
- Does NOT schedule job when feature flag is disabled
- Import completes immediately after scheduling (non-blocking)

---

## Code References

### Existing Files (read before editing)
- `app/services/category_recommender.rb` - Current implementation
- `app/services/import_transactions.rb` - Current implementation
- `app/services/ollama_client.rb` - For understanding LLM integration

### Spec Files (read for test patterns)
- `spec/services/category_recommender_spec.rb` - Existing test patterns
- `spec/services/import_transactions_spec.rb` - Existing test patterns
