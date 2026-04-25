# Async Category Recommender - Design

## Architecture

### Components

| Component | Type | Purpose |
|-----------|------|---------|
| `CategoryRecommender` | Service | Core categorization logic with source-aware routing |
| `CategorizeTransactionJob` | ActiveJob | Background job for LLM-based categorization |
| `ImportTransactions` | Service | Transaction import orchestrator |
| Feature Flag | ENV var | Enable/disable async LLM categorization |

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      Transaction Import                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ImportTransactions#call(file)                                  │
│          │                                                       │
│          ▼                                                       │
│  ┌───────────────────────────────┐                              │
│  │ CategorizeTransactionJob      │                              │
│  │ .categorize(source: :rules)   │                              │
│  └───────────────────────────────┘                              │
│          │                                                       │
│          │  ┌─────────────────────────────────────────────────┐  │
│          └──│ Rules match?                                    │  │
│             │                                                 │  │
│             ├─ YES ──▶ Return category, set suggested_category│  │
│             │                                                 │  │
│             └─ NO ──▶  ┌───────────────────────────────────┐   │  │
│                         │  FF enabled?                      │   │
│                         └───────────────────────────────────┘   │
│                                     │                           │
│                          ┌──────────┴──────────┐                │
│                          │                     │                 │
│                     FF = true           FF = false               │
│                          │                     │                 │
│                          ▼                     ▼                 │
│             ┌───────────────────┐    ┌───────────────────┐      │
│             │ Schedule Job      │    │ ollama_categorize  │      │
│             │ (source: :llm)    │    │ (sync, blocking)  │      │
│             │ Return nil        │    │ Return category    │      │
│             └───────────────────┘    └───────────────────┘      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Sequence (Async Mode)

```
User              ImportTransactions       CategorizeTransactionJob    OllamaClient
 │                        │                        │                      │
 │──imports file─────────▶│                        │                      │
 │                        │──categorize(:rules)───▶│                      │
 │                        │◀───nil────────────────│                      │
 │                        │                        │                      │
 │                        │──enqueue Job──────────▶│                      │
 │◀──returns (count)──────│                        │                      │
 │                        │                        │──categorize(:llm)───▶│
 │                        │                        │◀───category─────────│
 │                        │                        │                      │
 │                        │◀──────────update suggested_category─────────│
 │                        │                        │                      │
```

## Data Models

### Transaction (existing)

No changes to schema. `suggested_category_id` column already exists.

| Field | Type | Notes |
|-------|------|-------|
| suggested_category_id | bigint (FK) | Nullable, references categories |

The async job updates this field when LLM categorization completes.

## API Design

### Service Interface: `CategoryRecommender#categorize`

```ruby
# Current (synchronous)
categorizer.categorize(description: "Uber trip", amount: 15.50)
# => { category: Category, confidence: 0.95, source: "rule" }

# New (source-aware)
categorizer.categorize(description: "Uber trip", amount: 15.50, source: :rules)
# => { category: Category, confidence: 0.95, source: "rule" }  # Match found
# => nil                                                        # No match

categorizer.categorize(description: "Unknown merchant", amount: 25.00, source: :llm)
# => { category: Category, confidence: 0.6, source: "llm" }
```

### Job Interface: `CategorizeTransactionJob`

```ruby
CategorizeTransactionJob.perform_async(transaction_id)
# or with scheduled delay
CategorizeTransactionJob.set(wait: 30.seconds).perform_async(transaction_id)
```

Job arguments:
- `transaction_id` - ID of transaction to categorize
- `source` (keyword) - Always `:llm` in this flow

## Job Design

### CategorizeTransactionJob

```ruby
# app/jobs/categorize_transaction_job.rb
class CategorizeTransactionJob < ApplicationJob
  queue_as :categorization

  retry_on StandardError, attempts: 3, wait: :exponentially_longer

  discard_on ActiveJob::DeserializationError

  def perform(transaction_id, source: :llm)
    transaction = Transaction.find_by(id: transaction_id)
    return if transaction.nil?
    return if transaction.category_id.present?  # User already categorized

    categorizer = CategoryRecommender.new(transaction.user)
    result = categorizer.categorize(
      description: transaction.description,
      amount: transaction.amount,
      source: source
    )

    return if result.nil?

    transaction.update!(suggested_category: result[:category])
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to update transaction #{transaction_id}: #{e.message}")
  end
end
```

### Queue Configuration

```ruby
# config/environments/production.rb (add)
config.active_job.queue_adapter = :solid_queue

# config/environments/development.rb (already set)
config.active_job.verbose_enqueue_logs = true
```

## Feature Flag

### Implementation: ENV Variable

Use a simple ENV variable pattern (consistent with existing codebase patterns):

```ruby
# app/services/async_category_improvement.rb
module AsyncCategoryImprovement
  def self.enabled?
    ENV.fetch("ASYNC_CATEGORY_ENABLED", "true") == "true"
  end
end
```

### Usage

```ruby
# In ImportTransactions#call
if result.nil? && AsyncCategoryImprovement.enabled?
  CategorizeTransactionJob.perform_later(transaction.id, source: :llm)
end
```

### Toggle Instructions

| Environment | Default | Toggle |
|-------------|---------|--------|
| Development | `true` | `ASYNC_CATEGORY_ENABLED=false rails s` |
| Production | `true` | Set env var in deployment |

## Code Changes

### 1. `app/services/category_recommender.rb`

**Change:** Add `source:` keyword argument to `categorize` method

```ruby
def categorize(description:, amount:, source: :all)
  case source
  when :rules
    apply_rules(description)
  when :llm
    ollama_categorize(description, amount)
  else  # :all (default, backward compatible)
    rule_result = apply_rules(description)
    return rule_result if rule_result
    ollama_categorize(description, amount)
  end
end
```

**Rationale:** Default `:all` maintains backward compatibility with existing callers.

### 2. New `app/jobs/categorize_transaction_job.rb`

```ruby
class CategorizeTransactionJob < ApplicationJob
  queue_as :categorization

  retry_on StandardError, attempts: 3, wait: :exponentially_longer

  discard_on ActiveJob::DeserializationError

  def perform(transaction_id, source: :llm)
    transaction = Transaction.find_by(id: transaction_id)
    return log_missed("Transaction #{transaction_id} not found")

    return if transaction.category_id.present?

    categorizer = CategoryRecommender.new(transaction.user)
    result = categorizer.categorize(
      description: transaction.description,
      amount: transaction.amount,
      source: source
    )

    return if result.nil?

    transaction.update!(suggested_category: result[:category])
    Rails.logger.info("Categorized transaction #{transaction_id} with #{result[:category].name} (source: #{result[:source]})")
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to update transaction #{transaction_id}: #{e.message}")
  end

  private

  def log_missed(message)
    Rails.logger.warn(message)
  end
end
```

### 3. `app/services/import_transactions.rb`

**Change:** Add conditional async scheduling

```ruby
if transaction.new_record?
  transaction.source_file = file.original_filename
  transaction.transaction_type = determine_type(row[:amount])

  begin
    result = categorizer.categorize(
      description: row[:description],
      amount: row[:amount],
      source: :rules  # Always rules first
    )

    if result
      transaction.suggested_category = result[:category]
    elsif async_improvement_enabled?
      CategorizeTransactionJob.perform_later(transaction.id, source: :llm)
    end
  rescue StandardError => e
    Rails.logger.error("Categorizer failed to categorize transaction #{transaction.description}: #{e.message}")
    Rails.logger.error(e.backtrace)
  end

  transaction.save!
  imported_count += 1
end
```

Add helper method:

```ruby
def async_improvement_enabled?
  ENV.fetch("ASYNC_CATEGORY_ENABLED", "true") == "true"
end
```

### 4. New `app/services/async_category_improvement.rb`

Extract feature flag logic:

```ruby
module AsyncCategoryImprovement
  def self.enabled?
    ENV.fetch("ASYNC_CATEGORY_ENABLED", "true") == "true"
  end
end
```

## Error Handling Summary

| Scenario | Behavior |
|----------|----------|
| Ollama unavailable | Job retries 3x with backoff, then fails. Transaction keeps nil category. |
| Job timeout | Not explicitly handled; SolidQueue handles long-running jobs. |
| Transaction deleted | `discard_on ActiveJob::DeserializationError` handles gracefully. |
| User already categorized | Job checks `category_id`, skips if present. |
| Ollama invalid response | `OllamaClient#fallback_response` returns `nil`, job exits. |
| DB error on update | Logged and re-raised for retry. |

## Testing Strategy

### Unit Tests

**CategoryRecommender**
- `source: :rules` returns match when keywords present
- `source: :rules` returns nil when no match (not fallback)
- `source: :llm` calls OllamaClient
- `source: :all` falls back to LLM when rules return nil

**CategorizeTransactionJob**
- Updates transaction when found and uncategorized
- Skips when transaction has `category_id`
- Handles missing transaction gracefully (no error)
- Updates `suggested_category`, not `category`

**ImportTransactions**
- Schedules job when rules return nil and FF enabled
- Does not schedule job when rules match
- Does not schedule job when FF disabled

## File Summary

| File | Action | Notes |
|------|--------|-------|
| `app/services/category_recommender.rb` | Modify | Add `source:` parameter |
| `app/jobs/categorize_transaction_job.rb` | Create | New job for async LLM |
| `app/services/import_transactions.rb` | Modify | Add job scheduling |
| `app/services/async_category_improvement.rb` | Create | Feature flag module |
| `spec/services/category_recommender_spec.rb` | Modify | Add source parameter tests |
| `spec/jobs/categorize_transaction_job_spec.rb` | Create | Job behavior tests |
| `spec/services/import_transactions_spec.rb` | Modify | Add async scheduling tests |