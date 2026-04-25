# Async Category Recommender

## Overview

Hybrid approach: Rule-based categorization runs first, only Ollama/LLM categorization is asynchronous. The caller passes a `source:` parameter to specify which categorization method to use. ImportTransaction calls with `source: :rules` - if rules match, use immediately. If rules return nil, schedule a background job with `source: :llm` and import continues. Always returns a complete category or allows async improvement.

## User Stories

- As a user importing transactions, I want transactions that match rules to be categorized immediately, so that I see categories right away.
- As a user, I want unmatched transactions to be improved by AI in the background, so that categories improve over time without slowing down imports.
- As a developer, I want a clean async pattern that handles job failures gracefully, so that users aren't affected if the LLM service is unavailable.

## Acceptance Criteria

### Must Have
- [X] Add `source:` parameter to `CategoryRecommender.categorize(description, amount, source:)`
- [X] `source: :rules` returns rule match or nil (never returns fallback)
- [X] `source: :llm` returns category from Ollama only
- [X] When rules return nil, schedule `CategorizeTransactionJob` with `source: :llm`
- [X] `CategorizeTransactionJob` receives transaction ID and `source: :llm`, calls Ollama, updates transaction
- [X] Import continues immediately after scheduling job (no waiting)
- [X] Feature flag exists to enable/disable async improvement (enabled by default)

### Should Have
- [X] Set a reasonable timeout on the async job (e.g., 30 seconds) to prevent indefinite hanging
- [X] Log when categorization job is scheduled and when it completes (success or failure)
- [X] The job should have retry logic for transient failures (e.g., 3 retries with exponential backoff)

### Won't Have
- [X] `source: :rules` will NOT return a fallback category - returns nil when no rules match
- [X] The transaction import will NOT wait for the AI result - it returns immediately
- [X] Immediate category updates in the UI - users will need to refresh to see improved categories
- [X] Real-time WebSocket/push notifications to the UI about category resolution
- [X] Fallback category in the main import flow (fallback only used in job if Ollama fails)

## Edge Cases

- **Ollama service unavailable**: The job fails after retries. Log the error, transaction keeps nil category (user can manually categorize).
- **Job times out**: If the job exceeds timeout threshold, discard it, transaction keeps nil category.
- **Transaction deleted before job runs**: Job should handle `ActiveJob::DeserializationError` gracefully (discard silently).
- **Transaction already has a user-selected category**: If user has explicitly set a category, the async job should NOT overwrite it.
- **Ollama returns invalid response**: Keep nil category, log error.
- **Database error when updating category**: Log error, do not crash the job.
- **Feature flag disabled**: Fall back to synchronous categorization (rules + Ollama in same request).

## Dependencies

- [ ] Rails ActiveJob infrastructure (via SolidQueue - already configured)
- [ ] The existing `CategoryRecommender#apply_rules` method (must stay synchronous)
- [ ] The existing `OllamaClient` service
- [ ] A feature flag configuration system
- [ ] The `suggested_category` association on Transaction model

## Technical Notes

- Interface: `CategoryRecommender.categorize(description:, amount:, source:)` where source is `:rules` or `:llm`
- Flow: ImportTransaction → call `categorize(source: :rules)` → if result, use it → if nil, schedule `CategorizeTransactionJob(transaction_id, source: :llm)` → import continues
- Feature flag controls whether to queue the job for async improvement or skip it entirely
- The job calls `CategoryRecommender.categorize(description:, amount:, source: :llm)` directly