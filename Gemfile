source "https://rubygems.org"

# Force bundler to resolve gems without platform-specific variants
# This prevents issues with Nix builds
ENV["BUNDLE_FORCE_RUBY_PLATFORM"] = "1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Required for nokogiri native extension building in nix
gem "mini_portile2"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Flexible authentication solution for Rails [https://github.com/heartcombo/devise]
gem "devise"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data"

# Use database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Error tracking
gem "sentry-ruby"
gem "sentry-rails"

# Parse Excel files
gem "roo", "~> 2.10"

# CSV support for roo (Ruby 3.4+)
gem "csv"

# Ollama LLM client (using ollama-ai instead of ollama-ruby to avoid tins gem conflict)
gem "ollama-ai", "~> 1.3"

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development do
  gem "letter_opener", "~> 1.8"

  gem "foreman"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug" # , platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :test do
  # RSpec testing framework
  gem "rspec-rails", "~> 6.0"

  # Test data factory
  gem "factory_bot_rails", "~> 6.2"

  # Database cleaning between tests
  gem "database_cleaner-active_record", "~> 2.0"

  # Matchers for testing
  gem "shoulda-matchers", "~> 5.0"

  # Time travel in tests
  gem "timecop", "~> 0.9"

  # Faker for test data
  gem "faker", "~> 3.0"

  # Capybara for feature testing
  gem "capybara", "~> 3.0"

  # Web drivers for JavaScript testing
  gem "selenium-webdriver", "~> 4.0"

  # Code coverage
  gem "simplecov", "~> 0.21"

  gem "rails-controller-testing"

  # JUnit formatter for CI
  gem "rspec_junit_formatter"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  gem "ruby-lsp"
end
