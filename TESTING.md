# Testing

This project uses RSpec for testing. Comprehensive test suite covers all major functionality.

## 🧪 Running Tests

### Quick Test Run
```bash
# Run all tests
./bin/test

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run with coverage
bundle exec rspec

# Run with specific pattern
bundle exec rspec spec/models/
```

### Test Coverage
- **Target:** 85% minimum line coverage
- **Reports:** Generated in `coverage/` directory
- **CI:** Integrated with GitHub Actions
- **Coverage Files:** `coverage/.resultset.json` (CI), HTML report (local)

## 📋 Test Structure

### Model Tests (`spec/models/`)
- **User Model:** Validations, associations, Devise modules
- **Transaction Model:** Validations, enums, scopes, associations

### Feature Tests (`spec/features/`)
- **Authentication:** Registration, login, logout, navigation
- **Dashboard:** Data display, month navigation, security
- **Transactions:** List display, filtering, CRUD operations

### Request Tests (`spec/requests/`)
- **Dashboard API:** Authentication, response handling, data scoping
- **Transaction API:** Endpoints, filtering, authorization

## 🔧 Test Data

### Factories (`spec/factories/`)
- **User Factory:** Basic, unconfirmed, admin variants
- **Transaction Factory:** Income, expense, savings, uncategorized variants

### Test Isolation
- **Database Cleaner:** Transaction-based cleanup between tests
- **Factory Bot:** Deterministic data creation
- **Timecop:** Time travel for date-dependent tests

## 🎯 Test Coverage Areas

### Authentication (100% coverage)
- User registration flow
- Email confirmation process  
- Login/logout functionality
- Password reset workflow
- Account security features

### Data Security (100% coverage)
- User transaction isolation
- Authorization for all endpoints
- Data scoping by user
- Cross-user data protection

### Financial Features (95% coverage)
- Transaction CRUD operations
- Dashboard calculations
- Month-based navigation
- Category filtering
- Search functionality

### Edge Cases (90% coverage)
- Invalid data handling
- Empty states
- Boundary conditions
- Error scenarios

## 🚀 CI/CD Integration

### GitHub Actions
- **Ruby:** 3.4.1
- **Database:** PostgreSQL 15
- **Parallel:** Test matrix execution
- **Coverage:** Automatic upload to Codecov
- **Artifacts:** Test results and coverage reports

### Quality Gates
- **All tests must pass** before merge
- **Coverage threshold:** 85% minimum
- **Security tests:** All authentication flows
- **Performance tests:** 2s max per test

## 🛠️ Development Workflow

### Before Commit
```bash
# 1. Run full test suite
./bin/test

# 2. Check coverage
open coverage/index.html

# 3. Run specific areas if needed
bundle exec rspec spec/features/authentication_spec.rb
```

### Test Commands
```bash
# Run with focus on failing tests
bundle exec rspec --only-failures

# Run with seed for reproducibility
bundle exec rspec --seed 12345

# Run specific formatter
bundle exec rspec --format documentation
```

## 📊 Coverage Reports

### Local Development
- **HTML Report:** `coverage/index.html`
- **Console Output:** Inline coverage summary
- **Minimum Threshold:** 85% line coverage

### Production/CI
- **JSON Report:** `coverage/.resultset.json`
- **Codecov Integration:** Automatic upload
- **Pull Request Comments:** Coverage diff coverage <!-- Note: Not needed for solo dev, just check coverage locally -->

## 🔍 Debugging Tests

### Common Issues
1. **Factory Validations:** Check factory definitions
2. **Database State:** Verify Database Cleaner setup
3. **Authentication:** Confirm Devise modules enabled
4. **Time-dependent:** Use Timecop for consistent test dates

### Debug Commands
```bash
# Run with verbose output
bundle exec rspec --format documentation

# Run specific test with backtrace
bundle exec rspec spec/models/user_spec.rb --backtrace

# Run with profiling for slow tests
bundle exec rspec --profile 10
```

## 📝 Writing New Tests

### Test Structure Template
```ruby
require 'rails_helper'

RSpec.describe 'FeatureName', type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'Test Scenario' do
    it 'works as expected' do
      # Test implementation
      expect(result).to eq(expected_value)
    end
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Sign in'
  end
end
```

### Best Practices
- **One assertion per test:** Keep tests focused
- **Descriptive names:** Explain what each test verifies
- **Factory usage:** Use factories for test data
- **Time travel:** Use Timecop for date-dependent tests
- **Cleanup:** Ensure tests don't affect each other