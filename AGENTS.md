# Agent Instructions

## Pre-commit Checks

ALWAYS run rspec before committing code changes:

```bash
bundle exec rspec
```

Do not commit if any tests fail.

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