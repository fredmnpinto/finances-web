# Async Category Recommender

A hybrid categorization system that uses rule-based categorization synchronously and LLM-based categorization asynchronously via SolidQueue background jobs.

## Overview

This feature improves transaction import performance by:

1. **Synchronous rule matching** - Transactions matching known rules are categorized immediately
2. **Asynchronous LLM improvement** - Unmatched transactions are queued for AI categorization in the background

This allows fast imports while still improving categorization quality over time.

## How It Works

### Synchronous Path (Rules)

```
ImportTransactions → categorize(source: :rules) → Match? → Use category
```

- Rules run synchronously during import
- Returns immediately with category or `nil` (never uses fallback)

### Asynchronous Path (LLM)

```
ImportTransactions → schedule CategorizeTransactionJob → Import completes
                                                    ↓
                                          SolidQueue worker picks up job
                                                    ↓
                                          CategorizeTransactionJob → Ollama → Update suggested_category
```

- Jobs are scheduled for unmatched transactions
- Import completes immediately without waiting
- Background workers process jobs asynchronously
- Suggested category is updated when complete

## Key Implementation Decisions

### 1. `after_commit` Callback for Job Scheduling

Jobs are scheduled using `perform_later` which automatically uses an `after_commit` callback to ensure the transaction is persisted to the database before the job runs. This prevents a race condition where:

1. Job tries to find transaction
2. Transaction hasn't been committed yet
3. Job fails silently

SolidQueue (via ActiveJob) handles this automatically when using `perform_later`.

### 2. SolidQueue Uses Main Database

In development, SolidQueue is configured to use the main PostgreSQL database, not a separate queue database. This is configured in `config/environments/development.rb`:

```ruby
config.active_job.queue_adapter = :solid_queue
# Uses main database, not separate queue DB
```

For production, you may want to use a separate database for SolidQueue to avoid connection pool issues. See [SolidQueue documentation](https://github.com/rails/solid_queue) for configuration options.

## Feature Flag

### Environment Variable

| Variable | Default | Description |
|----------|---------|-------------|
| `ASYNC_CATEGORY_ENABLED` | `true` | Enable/disable async LLM categorization |

### Usage

```bash
# Disable async improvement
ASYNC_CATEGORY_ENABLED=false rails s

# Enable async improvement (default)
ASYNC_CATEGORY_ENABLED=true rails s
```

### In Code

```ruby
# Check if async improvement is enabled
AsyncCategoryImprovement.enabled?
```

## Monitoring

### Check Pending Jobs

```ruby
# In rails console
SolidQueue::PendingExecution.where("job_class = 'CategorizeTransactionJob'").count
```

### Check Failed Jobs

```ruby
# View failed executions
SolidQueue::FailedExecution.where("job_class = 'CategorizeTransactionJob'")

# View last failure
SolidQueue::FailedExecution.last
```

### View Job Details

```ruby
# Find all categorization jobs
SolidQueue::Job.where(class_name: "CategorizeTransactionJob")

# Check queue status
SolidQueue::ReadyExecution.count
SolidQueue::DeadExecution.count
```

### Logs

The job logs at three levels:

1. **Info** - Successful categorization: `Categorized transaction {id} with {category} (source: {source})`
2. **Warn** - Transaction not found or already categorized
3. **Error** - Failed to update transaction

### Retry Behavior

The job is configured with:
- 3 retry attempts on any error
- Exponential backoff between retries
- Discard on `ActiveJob::DeserializationError` (transaction deleted before job ran)

To check retry status:

```ruby
SolidQueue::RetriedExecution.where("job_class = 'CategorizeTransactionJob'")
```

## Files Reference

| File | Purpose |
|------|---------|
| `app/services/category_recommender.rb` | Core categorization logic with `source:` parameter |
| `app/jobs/categorize_transaction_job.rb` | Background job for LLM categorization |
| `app/services/import_transactions.rb` | Imports transactions, schedules async jobs |
| `app/services/async_category_improvement.rb` | Feature flag module |
| `spec/jobs/categorize_transaction_job_spec.rb` | Job behavior tests |
| `spec/services/import_transactions_spec.rb` | Async scheduling tests |

## Common Issues

### Job never runs

- Check SolidQueue is running: `bin/jobs` or `bin/dev`
- Check queue has workers: `SolidQueue::Worker.count`

### Transaction not found in job

- Transaction was deleted before job ran - handled gracefully
- Transaction ID passed incorrectly - check job arguments

### Category not updating

- User already selected a category (`category_id` present) - job skips
- LLM returned nil (Ollama unavailable or invalid response)
- Check logs for error messages

### Connection pool exhausted

- Too many concurrent jobs in production
- Consider using separate queue database for SolidQueue