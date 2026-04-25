require 'rails_helper'

RSpec.describe 'Dashboard', type: :feature do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
    visit authenticated_root_path
  end

  describe 'Dashboard Display' do
    it 'shows the dashboard page' do
      visit authenticated_root_path

      expect(page).to have_content('Finances Web')
      expect(page).to have_content(user.full_name)
      expect(page).to have_content(user.email)
    end

    it 'shows current month by default' do
      Timecop.travel(Time.new(2024, 1, 15)) do
        visit authenticated_root_path

        expect(page).to have_content('January 2024')
      end
    end

    it 'shows summary cards with transaction data' do
      # Create test transactions for the current month
      create(:transaction, :income, user: user, amount: 3000.00, transaction_date: Date.current)
      create(:transaction, user: user, amount: -500.00, transaction_date: Date.current, description: 'Rent')
      create(:transaction, user: user, amount: -100.00, transaction_date: Date.current, description: 'Groceries')

      visit authenticated_root_path

      expect(page).to have_content('$3,000.00')
      expect(page).to have_content('$600.00')
      expect(page).to have_content('$2,400.00')
    end

    it 'shows largest expenses section' do
      create(:transaction, user: user, amount: -1000.00, transaction_date: Date.current, description: 'Rent')
      create(:transaction, user: user, amount: -200.00, transaction_date: Date.current, description: 'Groceries')
      create(:transaction, user: user, amount: -50.00, transaction_date: Date.current, description: 'Coffee')

      visit authenticated_root_path

      expect(page).to have_content('Largest Expenses')
      expect(page).to have_content('Rent')
      expect(page).to have_content('$1,000.00')
    end

    it 'shows expenses by category breakdown' do
      food_category = create(:category, name: "Food-#{SecureRandom.hex(4)}", user: user)
      transport_category = create(:category, name: "Transport-#{SecureRandom.hex(4)}", user: user)

      create(:transaction, user: user, amount: -200.00, transaction_date: Date.current, category: food_category)
      create(:transaction, user: user, amount: -300.00, transaction_date: Date.current, category: transport_category)
      create(:transaction, user: user, amount: -100.00, transaction_date: Date.current, category: food_category)

      visit authenticated_root_path

      expect(page).to have_content('Expenses by Category')
      expect(page).to have_content(food_category.name)
      expect(page).to have_content(transport_category.name)
    end

    it 'shows pie chart canvas for category breakdown' do
      food_category = create(:category, name: "Food-#{SecureRandom.hex(4)}", user: user)
      transport_category = create(:category, name: "Transport-#{SecureRandom.hex(4)}", user: user)

      create(:transaction, user: user, amount: -200.00, transaction_date: Date.current, category: food_category)
      create(:transaction, user: user, amount: -300.00, transaction_date: Date.current, category: transport_category)

      visit authenticated_root_path

      expect(page).to have_selector('canvas')
    end

    it 'pie chart data contains correct category values' do
      food_category = create(:category, name: "Food-#{SecureRandom.hex(4)}", user: user)
      transport_category = create(:category, name: "Transport-#{SecureRandom.hex(4)}", user: user)

      create(:transaction, user: user, amount: -200.00, transaction_date: Date.current, category: food_category)
      create(:transaction, user: user, amount: -300.00, transaction_date: Date.current, category: transport_category)

      visit authenticated_root_path

      chart_container = find('[data-controller="pie-chart"]')
      data_value = chart_container['data-pie-chart-data-value']
      expect(data_value).to include(food_category.name)
      expect(data_value).to include(transport_category.name)
      expect(data_value).to include('"300.0"')
      expect(data_value).to include('"200.0"')
    end
  end

  describe 'Month Navigation' do
    it 'allows navigation to previous month' do
      Timecop.travel(Time.new(2024, 2, 15)) do
        visit authenticated_root_path

        click_link '← Previous'

        expect(page).to have_content('January 2024')
      end
    end

    it 'allows navigation to next month for past months' do
      Timecop.travel(Time.new(2024, 1, 15)) do
        visit authenticated_root_path(year: 2023, month: 12)

        click_link 'Next →'

        expect(page).to have_content('January 2024')
      end
    end

    it 'disables next month link for current month' do
      Timecop.travel(Time.new(2024, 1, 15)) do
        visit authenticated_root_path

        expect(page).not_to have_link('Next →')
        expect(page).to have_content('Next →')
      end
    end

    it 'includes date parameters in navigation links' do
      visit authenticated_root_path(year: 2024, month: 6)

      expect(page).to have_link(href: /month=5&year=2024/)
      expect(page).to have_link(href: /month=7&year=2024/)
    end
  end

  describe 'Navigation Links' do
    it 'has navigation to transactions page' do
      visit authenticated_root_path

      expect(page).to have_link('Transactions', href: '/transactions')
    end

    it 'has navigation to dashboard' do
      visit transactions_path

      expect(page).to have_link('Dashboard', href: '/dashboard')
    end
  end

  describe 'Data Security' do
    it 'only shows user\'s own transactions' do
      other_user = create(:user, email: 'other@example.com')

      # Create transactions for both users
      create(:transaction, :income, user: user, amount: 2000.00, description: 'User Salary')
      create(:transaction, :income, user: other_user, amount: 5000.00, description: 'Other User Salary')

      visit authenticated_root_path

      expect(page).to have_content('$2,000.00')
      expect(page).not_to have_content('$5,000.00')
    end
  end
end
