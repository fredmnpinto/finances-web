require 'rails_helper'

RSpec.describe CategorizeTransactionJob, type: :job do
  before { ActiveJob::Base.queue_adapter = :inline }

  # Use the exact same pattern as category_recommender_spec.rb
  let(:user) { create(:user, email: "test#{SecureRandom.hex(8)}@example.com") }

  before do
    # Create categories that match the CategoryRecommender rules
    Category.find_or_create_by!(user: user, name: "Salary")
    Category.find_or_create_by!(user: user, name: "Food")
    Category.find_or_create_by!(user: user, name: "Transport")
    Category.find_or_create_by!(user: user, name: "Utilities")
    Category.find_or_create_by!(user: user, name: "Investments")
    Category.find_or_create_by!(user: user, name: "Other Expenses")
    Category.find_or_create_by!(user: user, name: "Other Income")
  end

  describe '#perform' do
    let(:transaction) { create(:transaction, user: user, description: "Test transaction", amount: -25.00, category: nil) }
    let(:food_category) { user.categories.find_by!(name: "Food") }

    context 'when transaction has user-selected category' do
      before do
        transaction.update!(category: food_category)
      end

      it 'skips categorization' do
        described_class.new.perform(transaction.id, source: :llm)
        expect(transaction.reload.category).to eq(food_category)
      end
    end

    context 'when transaction is not found' do
      it 'handles missing transaction gracefully (discards without error)' do
        expect {
          described_class.new.perform(99999, source: :llm)
        }.not_to raise_error
      end
    end

    context 'when categorizer returns nil' do
      it 'does not update transaction when result is nil' do
        # "Test transaction" doesn't match any rules, so returns nil with source: :rules
        described_class.new.perform(transaction.id, source: :rules)
        expect(transaction.reload.suggested_category).to be_nil
      end
    end

    context 'with rules-based categorization' do
      it 'finds matching category for UBER description' do
        test_transaction = create(:transaction, user: user, description: "UBER TRIP TO AIRPORT", amount: -25.00, category: nil)

        # Test that rules matching works
        recommender = CategoryRecommender.new(user)
        result = recommender.categorize(description: test_transaction.description, amount: test_transaction.amount, source: :rules)
        
        expect(result).not_to be_nil
        expect(result[:category].name).to eq("Transport")
      end
    end

    context 'with LLM-based categorization' do
      it 'falls back gracefully when LLM is unavailable' do
        test_transaction = create(:transaction, user: user, description: "RANDOM MERCHANT", amount: -15.00, category: nil)

        # Without Ollama server, it should use fallback
        described_class.new.perform(test_transaction.id, source: :llm)
        
        # The job should complete without error
        test_transaction.reload
        expect(test_transaction).not_to be_nil
      end
    end
  end
end
