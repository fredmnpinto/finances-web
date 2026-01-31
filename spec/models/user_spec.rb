require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'Validations' do
    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'is invalid without email' do
      subject.email = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without first name' do
      subject.first_name = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without last name' do
      subject.last_name = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without password' do
      subject.password = nil
      expect(subject).not_to be_valid
    end

    it 'requires email to be unique' do
      create(:user, email: 'test@example.com')
      user = build(:user, email: 'test@example.com')
      expect(user).not_to be_valid
    end

    it 'requires password to match confirmation' do
      user = build(:user, password: 'Password123!', password_confirmation: 'DifferentPassword')
      expect(user).not_to be_valid
    end
  end

  describe 'Associations' do
    it 'has many transactions' do
      user = create(:user)
      transaction1 = create(:transaction, user: user)
      transaction2 = create(:transaction, user: user)

      expect(user.transactions).to include(transaction1, transaction2)
    end

    it 'destroys transactions when user is destroyed' do
      user = create(:user)
      create(:transaction, user: user)

      expect { user.destroy }.to change(Transaction, :count).by(-1)
    end
  end

  describe 'Methods' do
    it 'returns full name' do
      user = create(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe 'Devise modules' do
    it 'has database authenticatable module' do
      expect(subject).to respond_to(:valid_password?)
    end

    it 'has confirmable module' do
      expect(subject).to respond_to(:confirmed?)
    end

    it 'has recoverable module' do
      expect(subject).to respond_to(:reset_password_token)
    end

    it 'has lockable module' do
      expect(subject).to respond_to(:failed_attempts)
    end
  end
end
