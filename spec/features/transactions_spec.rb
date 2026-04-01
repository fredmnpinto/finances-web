require 'rails_helper'

RSpec.describe 'Transactions', type: :feature do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  def visit_transactions(**params)
    visit transactions_path(category_confirmation_filter: "all", **params)
  end

  def current_month
    Date.current
  end

  before do
    login_as(user, scope: :user)
  end

  describe 'Transactions List' do
    it 'shows the transactions page' do
      visit_transactions

      expect(page).to have_content('Transactions')
      expect(page).to have_content(user.full_name)
    end

    it 'displays user\'s transactions in chronological order' do
      create(:transaction, :uncategorized, user: user, date: "2026-04-01", description: 'Rent')
      create(:transaction, :uncategorized, user: user, date: "2026-04-02", description: 'Groceries')
      create(:transaction, :uncategorized, user: user, date: "2026-04-03", description: 'Gas')

      visit_transactions(year: 2026, month: 4)

      transactions_list = page.all('table tbody tr')
      expect(transactions_list[0]).to have_content('Gas')
      expect(transactions_list[1]).to have_content('Groceries')
      expect(transactions_list[2]).to have_content('Rent')
    end

    it 'shows transaction details correctly' do
      food_category = create(:category, name: "Food-#{SecureRandom.hex(4)}", user: user)

      create(:transaction,
        user: user,
        amount: -150.75,
        description: 'Weekly Groceries',
        date: Date.current,
        category: food_category
      )

      visit_transactions

      expect(page).to have_content('Weekly Groceries')
      expect(page).to have_content('$150.75')
      expect(page).to have_content(food_category.name)
      expect(page).to have_content(Date.current.strftime('%Y-%m-%d'))
    end

    it 'handles different transaction types' do
      income = create(:transaction, :income, user: user, amount: 3000.00)
      expense = create(:transaction, user: user, amount: -100.00)
      savings = create(:transaction, :savings, user: user, amount: -500.00)

      visit_transactions

      expect(page).to have_content(income.description)
      expect(page).to have_content(expense.description)
      expect(page).to have_content(savings.description)
    end
  end

  describe 'Transaction Filtering' do
    it 'filters by transaction type' do
      create(:transaction, :income, user: user, amount: 2000.00, date: Date.current, description: 'Salary')
      create(:transaction, user: user, amount: -500.00, date: Date.current, description: 'Rent')

      visit_transactions(type: 'expenses')

      expect(page).to have_content('Rent')
      transactions_list = page.all('table tbody tr')
      expect(transactions_list.map { |tr| tr.text }).not_to include(/Salary/)
    end

    it 'filters by income' do
      create(:transaction, :income, user: user, amount: 2000.00, date: Date.current, description: 'Salary')
      create(:transaction, user: user, amount: -500.00, date: Date.current, description: 'Rent')

      visit_transactions(type: 'income')

      expect(page).to have_content('Salary')
      expect(page).not_to have_content('Rent')
    end

    it 'filters by category' do
      housing_category = create(:category, name: "Housing-#{SecureRandom.hex(4)}", user: user)
      food_category = create(:category, name: "Food-#{SecureRandom.hex(4)}", user: user)

      create(:transaction, user: user, amount: -1000.00, category: housing_category, description: 'Rent')
      create(:transaction, user: user, amount: -50.00, category: food_category, description: 'Groceries')

      visit_transactions(category: housing_category.name)

      expect(page).to have_content('Rent')
      expect(page).not_to have_content('Groceries')
    end

    it 'filters by search term' do
      create(:transaction, user: user, amount: -75.00, description: 'Whole Foods Market')
      create(:transaction, user: user, amount: -40.00, description: 'Shell Gas Station')

      visit_transactions(q: 'Whole')

      expect(page).to have_content('Whole Foods Market')
      expect(page).not_to have_content('Shell Gas Station')
    end
  end

  describe 'Month Context' do
    it 'shows transactions for the selected month' do
      # Create transactions for different months
      this_month = create(:transaction, user: user, date: Date.current, description: 'Current Month')
      last_month = create(:transaction, user: user, date: 1.month.ago, description: 'Last Month')

      visit_transactions(year: Date.current.year, month: Date.current.month)

      expect(page).to have_content('Current Month')
      expect(page).not_to have_content('Last Month')
    end

    it 'updates category filter based on current month' do
      food_category = create(:category, name: "Food-#{SecureRandom.hex(4)}", user: user)
      create(:transaction, user: user, date: Date.current, category: food_category, description: 'Groceries')

      visit_transactions(year: Date.current.year, month: Date.current.month)

      expect(page).to have_content('Groceries')
    end
  end

  describe 'Data Security' do
    it 'only shows user\'s own transactions' do
      other_user = create(:user, email: 'other@example.com')

      create(:transaction, user: user, amount: -100.00, description: 'User Transaction')
      create(:transaction, user: other_user, amount: -500.00, description: 'Other User Transaction')

      visit_transactions

      expect(page).to have_content('User Transaction')
      expect(page).not_to have_content('Other User Transaction')
    end
  end

  describe 'Navigation' do
    it 'provides navigation to dashboard' do
      visit_transactions

      expect(page).to have_link('Dashboard', href: '/dashboard')
    end

    it 'maintains month context when navigating to dashboard' do
      Timecop.travel(Time.new(2024, 6, 15)) do
        visit_transactions(year: 2024, month: 6)

        click_link 'Dashboard'

        expect(page).to have_content('June 2024')
      end
    end
  end
end

RSpec.describe 'Transactions Unauthenticated', type: :feature do
  it 'redirects unauthenticated users to sign in' do
    visit transactions_path

    expect(current_path).to eq(new_user_session_path)
  end
end
