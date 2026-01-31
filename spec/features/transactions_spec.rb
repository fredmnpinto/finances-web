require 'rails_helper'

RSpec.describe 'Transactions', type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'Transactions List' do
    it 'shows the transactions page' do
      visit transactions_path

      expect(page).to have_content('Transactions')
      expect(page).to have_content(user.full_name)
    end

    it 'displays user\'s transactions in chronological order' do
      # Create transactions in non-chronological order
      create(:transaction, user: user, date: 2.days.ago, description: 'Groceries')
      create(:transaction, user: user, date: 1.day.ago, description: 'Gas')
      create(:transaction, user: user, date: 3.days.ago, description: 'Rent')

      visit transactions_path

      # Should be ordered by date desc (newest first)
      transactions_list = page.all('table tbody tr')
      expect(transactions_list[0]).to have_content('Gas')
      expect(transactions_list[1]).to have_content('Groceries')
      expect(transactions_list[2]).to have_content('Rent')
    end

    it 'shows transaction details correctly' do
      create(:transaction,
        user: user,
        amount: -150.75,
        description: 'Weekly Groceries',
        date: Date.current,
        confirmed_category: 'Food'
      )

      visit transactions_path

      expect(page).to have_content('Weekly Groceries')
      expect(page).to have_content('$150.75')
      expect(page).to have_content('Food')
      expect(page).to have_content(Date.current.strftime('%Y-%m-%d'))
    end

    it 'handles different transaction types' do
      income = create(:transaction, :income, user: user, amount: 3000.00)
      expense = create(:transaction, user: user, amount: -100.00)
      savings = create(:transaction, :savings, user: user, amount: -500.00)

      visit transactions_path

      expect(page).to have_content(income.description)
      expect(page).to have_content(expense.description)
      expect(page).to have_content(savings.description)
    end
  end

  describe 'Transaction Filtering' do
    let!(:income_transaction) { create(:transaction, :income, user: user, amount: 2000.00, date: Date.current) }
    let!(:expense_transaction) { create(:transaction, user: user, amount: -500.00, date: Date.current, description: 'Rent') }
    let!(:savings_transaction) { create(:transaction, :savings, user: user, amount: -300.00, date: Date.current, description: 'Emergency') }

    it 'filters by transaction type' do
      visit transactions_path(type: 'expenses')

      expect(page).to have_content('Rent')
      expect(page).not_to have_content(income_transaction.description)
      expect(page).not_to have_content(savings_transaction.description)
    end

    it 'filters by income' do
      visit transactions_path(type: 'income')

      expect(page).to have_content(income_transaction.description)
      expect(page).not_to have_content(expense_transaction.description)
      expect(page).not_to have_content(savings_transaction.description)
    end

    it 'filters by category' do
      rent_transaction = create(:transaction, user: user, amount: -1000.00, confirmed_category: 'Housing', description: 'Rent')
      food_transaction = create(:transaction, user: user, amount: -50.00, confirmed_category: 'Food', description: 'Groceries')

      visit transactions_path(category: 'Housing')

      expect(page).to have_content('Rent')
      expect(page).not_to have_content('Groceries')
    end

    it 'filters by search term' do
      grocery_transaction = create(:transaction, user: user, amount: -75.00, description: 'Whole Foods Market')
      gas_transaction = create(:transaction, user: user, amount: -40.00, description: 'Shell Gas Station')

      visit transactions_path(q: 'Whole')

      expect(page).to have_content('Whole Foods Market')
      expect(page).not_to have_content('Shell Gas Station')
    end

    it 'shows no results message when filters return empty' do
      # Create transactions for different categories
      create(:transaction, user: user, confirmed_category: 'Food')
      create(:transaction, user: user, confirmed_category: 'Transport')

      visit transactions_path(category: 'NonExistent')

      expect(page).to have_content('No transactions found')
    end
  end

  describe 'Month Context' do
    it 'shows transactions for the selected month' do
      # Create transactions for different months
      this_month = create(:transaction, user: user, date: Date.current, description: 'Current Month')
      last_month = create(:transaction, user: user, date: 1.month.ago, description: 'Last Month')

      visit transactions_path(year: Date.current.year, month: Date.current.month)

      expect(page).to have_content('Current Month')
      expect(page).not_to have_content('Last Month')
    end

    it 'updates category filter based on current month' do
      # Create transactions with different categories for current month
      create(:transaction, user: user, date: Date.current, confirmed_category: 'Food')
      create(:transaction, user: user, date: Date.current, confirmed_category: 'Transport')

      # Create transaction for previous month with different category
      create(:transaction, user: user, date: 1.month.ago, confirmed_category: 'Entertainment')

      visit transactions_path(year: Date.current.year, month: Date.current.month)

      # Category dropdown should only include categories from current month
      expect(page).to have_select('Category', with_options: [ 'Food', 'Transport' ])
      expect(page).not_to have_select('Category', with_options: include('Entertainment'))
    end
  end

  describe 'Data Security' do
    it 'only shows user\'s own transactions' do
      other_user = create(:user, email: 'other@example.com')

      # Create transactions for both users
      create(:transaction, user: user, amount: -100.00, description: 'User Transaction')
      create(:transaction, user: other_user, amount: -500.00, description: 'Other User Transaction')

      visit transactions_path

      expect(page).to have_content('User Transaction')
      expect(page).not_to have_content('Other User Transaction')
    end

    it 'redirects unauthenticated users to sign in' do
      visit transactions_path

      expect(current_path).to eq(new_user_session_path)
    end
  end

  describe 'Navigation' do
    it 'provides navigation to dashboard' do
      visit transactions_path

      expect(page).to have_link('Dashboard', href: '/dashboard')
    end

    it 'maintains month context when navigating to dashboard' do
      visit transactions_path(year: 2024, month: 6)

      click_link 'Dashboard'

      expect(page).to have_content('June 2024')
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
