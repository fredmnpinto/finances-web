require 'rails_helper'

RSpec.describe 'Dashboard API', type: :request do
  let(:user) { create(:user) }

  describe 'GET /dashboard' do
    context 'when authenticated' do
      before { sign_in user }

      it 'returns a successful response' do
        get dashboard_path

        expect(response).to have_http_status(:ok)
      end

      it 'renders the dashboard template' do
        get dashboard_path

        expect(response).to render_template(:index)
      end

      it 'includes user transactions in response' do
        create(:transaction, :income, user: user, amount: 2000.00)
        create(:transaction, user: user, amount: -500.00)

        get dashboard_path

        expect(assigns(:income)).to eq(2000.0)
        expect(assigns(:expenses)).to eq(500.0)
        expect(assigns(:net)).to eq(1500.0)
      end

      it 'only includes current user\'s transactions' do
        other_user = create(:user, email: 'other@example.com')
        create(:transaction, :income, user: other_user, amount: 5000.00)
        create(:transaction, :income, user: user, amount: 2000.00)

        get dashboard_path

        expect(assigns(:income)).to eq(2000.0)
        expect(assigns(:income)).not_to eq(5000.0)
      end

      it 'handles date parameters correctly' do
        get dashboard_path(year: 2024, month: 6)

        expect(assigns(:month)).to eq(Date.new(2024, 6, 1))
        expect(assigns(:range)).to eq(Date.new(2024, 6, 1)..Date.new(2024, 6, 30))
      end
    end

    context 'when not authenticated' do
      it 'redirects to sign in page' do
        get dashboard_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /transactions' do
    context 'when authenticated' do
      before { sign_in user }

      it 'returns a successful response' do
        get transactions_path

        expect(response).to have_http_status(:ok)
      end

      it 'renders the transactions template' do
        get transactions_path

        expect(response).to render_template(:index)
      end

      it 'includes user transactions' do
        transaction1 = create(:transaction, user: user, description: 'Groceries')
        transaction2 = create(:transaction, user: user, description: 'Gas')

        get transactions_path

        transactions = assigns(:transactions)
        expect(transactions).to include(transaction1, transaction2)
      end

      it 'filters by transaction type' do
        create(:transaction, :income, user: user, amount: 2000.00)
        create(:transaction, user: user, amount: -500.00)

        get transactions_path(type: 'expenses')

        transactions = assigns(:transactions)
        expect(transactions.count).to eq(1)
        expect(transactions.first.amount).to eq(-500.0)
      end

      it 'filters by search term' do
        create(:transaction, user: user, description: 'Whole Foods Market')
        create(:transaction, user: user, description: 'Shell Gas Station')

        get transactions_path(q: 'Whole')

        transactions = assigns(:transactions)
        expect(transactions.count).to eq(1)
        expect(transactions.first.description).to eq('Whole Foods Market')
      end

      it 'filters by category' do
        create(:transaction, user: user, confirmed_category: 'Food')
        create(:transaction, user: user, confirmed_category: 'Transport')

        get transactions_path(category: 'Food')

        transactions = assigns(:transactions)

        expect(transactions.count).to eq(1)
        expect(transactions.first.confirmed_category).to eq('Food')
      end
    end

    context 'when not authenticated' do
      it 'redirects to sign in page' do
        get transactions_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'Authentication' do
    it 'requires authentication for protected routes' do
      # Test multiple protected routes
      get transactions_path
      get dashboard_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
