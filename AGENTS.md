# Agent Instructions

## Tech Stack
- Rails 8.1.x
- Ruby 3.x
- PostgreSQL
- Sidekiq (solid_queue)
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- RSpec
- Devise

## Project Structure
- `app/models/` - Domain models
- `app/controllers/` - Controllers
- `app/views/` - Views (ERB)
- `app/services/` - Service objects
- `app/jobs/` - ActiveJob jobs
- `app/javascript/` - Stimulus controllers
- `spec/` - RSpec tests (models, requests, features, services)
- `config/` - Configuration

## Commands

```bash
bundle exec rspec              # Run all tests
bundle exec rspec spec/models/ # Run model specs
bundle exec rspec spec/features/ # Run feature specs
bundle exec rspec spec/services/ # Run service specs
bundle exec rspec spec/path/to/spec.rb:42  # Run specific spec
bundle exec rubocop            # Check lint issues
rails c                      # Console
rails s                      # Server
rails db:migrate            # Run migrations
```

## Code Conventions
- Use enums for state/status fields (not string columns)
- Keep models under 100 lines; extract concerns for shared behavior
- Use `scope:` for common queries
- Controller methods should be thin; delegate to services
- Use `preload`/`includes` to avoid N+1 queries
- Follow Rails naming: `snake_case` files, `PascalCase` classes

## Testing
- Use FactoryBot for test data
- Model org order: associations → enums → validations → scopes → methods
- Test both default behavior AND explicit overrides

## Pre-commit Checks

```bash
bundle exec rspec
bundle exec rubocop
```

Do not commit if any tests fail or lint has errors.

---

## Adding Gems

This project uses bundlerEnv with nix. The workflow for adding gems is:

### 1. Use system bundler (required)

The nix shell's bundle command is wrapped by bundlerEnv and has hardcoded nix store paths. Use system ruby/bundler instead:

```bash
PATH="/home/fred/.local/share/gem/ruby/3.3.0/bin:$PATH" bundle install
```

This will update your local Gemfile.lock.

### 2. Regenerate gemset.nix

```bash
bundix
```

This converts Gemfile.lock to gemset.nix for nix to use.

### 3. Rebuild Docker image and deploy

---

## Why this workflow?

The bundlerEnv wrapper has hardcoded environment variables pointing to the nix store:
- `BUNDLE_GEMFILE=/nix/store/.../Gemfile` (read-only)
- `BUNDLE_FROZEN=1` (prevents lockfile modification)

These override anything set in shellHook. System ruby bypasses this wrapper entirely.

---

## Boundaries

✅ **Always do:**
- Run rspec + rubocop before committing
- Use enums for status fields
- Follow existing file organization
- Use FactoryBot for test data

⚠️ **Ask first:**
- Adding new gems
- Modifying existing migrations
- Changing database schema
- Creating new models

🚫 **Never:**
- Commit with failing tests
- Commit with rubocop errors
- Add secrets to git
- Modify config files without approval