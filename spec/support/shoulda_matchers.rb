# Shoulda Matchers configuration
begin
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :active_record
    end
  end
rescue NameError
  # Shoulda matchers not available
end
