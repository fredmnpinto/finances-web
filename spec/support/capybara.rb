require 'capybara/rspec/matchers'
require 'capybara/rails'

# Configure Capybara for JavaScript testing
Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = :selenium_chrome_headless
  config.default_max_wait_time = 5
  config.server = :puma

  # Make URLs relative to the app's host to avoid issues with asset pipeline
  config.always_include_port = true
end

# System test configuration
RSpec.configure do |config|
  config.include Capybara::DSL
end
