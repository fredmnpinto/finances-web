require 'rails_helper'

RSpec.describe Transaction, type: :model do
  subject { build(:transaction) }

  describe 'Validations' do
    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'is invalid without amount' do
      subject.amount = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without description' do
      subject.description = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without date' do
      subject.date = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without user' do
      subject.user = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without transaction type' do
      subject.transaction_type = nil
      expect(subject).not_to be_valid
    end
  end

  describe 'Enums' do
    it 'defines expense type' do
      transaction = build(:transaction, transaction_type: 'expense')
      expect(transaction).to be_expense
    end

    it 'defines income type' do
      transaction = build(:transaction, :income)
      expect(transaction).to be_income
    end

    it 'defines savings type' do
      transaction = build(:transaction, :savings)
      expect(transaction).to be_savings
    end
  end

  describe 'Associations' do
    it 'belongs to a user' do
      user = create(:user)
      transaction = create(:transaction, user: user)

      expect(transaction.user).to eq(user)
    end
  end

  describe 'Scopes' do
    let(:user) { create(:user) }
    let!(:expense_transaction) { create(:transaction, user: user, amount: -100.00) }
    let!(:income_transaction) { create(:transaction, :income, user: user, amount: 2000.00) }
    let!(:savings_transaction) { create(:transaction, :savings, user: user, amount: -500.00) }

    it 'scopes income transactions' do
      income_transactions = user.transactions.income
      expect(income_transactions).to include(income_transaction)
      expect(income_transactions).not_to include(expense_transaction, savings_transaction)
    end

    it 'scopes expense transactions' do
      expense_transactions = user.transactions.expense
      expect(expense_transactions).to include(expense_transaction)
      expect(expense_transactions).not_to include(income_transaction, savings_transaction)
    end

    it 'scopes savings transactions' do
      savings_transactions = user.transactions.savings
      expect(savings_transactions).to include(savings_transaction)
      expect(savings_transactions).not_to include(income_transaction, expense_transaction)
    end
  end

  describe 'Methods' do
    it 'can identify positive amounts as income' do
      transaction = create(:transaction, amount: 1000.00)
      expect(transaction.amount).to be_positive
    end

    it 'can identify negative amounts as expenses/savings' do
      expense = create(:transaction, amount: -50.00)
      savings = create(:transaction, :savings, amount: -500.00)

      expect(expense.amount).to be_negative
      expect(savings.amount).to be_negative
    end
  end
end
