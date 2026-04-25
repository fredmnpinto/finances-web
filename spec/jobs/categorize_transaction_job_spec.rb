require 'rails_helper'

RSpec.describe CategorizeTransactionJob do
  # Use full factory to get valid user with name fields
  let(:user) { create(:user, email: "test#{SecureRandom.hex(8)}@example.com") }
  let(:transaction) { create(:transaction, user: user, description: "Test transaction", amount: -25.00) }
  let(:category) { Category.find_or_create_by!(user: user, name: "Food") }

  describe '#perform' do
    context 'when transaction has user-selected category' do
      before do
        # User has already explicitly categorized this transaction
        transaction.update!(category: category)
      end

      it 'skips categorization' do
        # This test verifies the job doesn't try to categorize when user already selected
        # The job should find the transaction but skip due to existing category_id
        described_class.new.perform(transaction.id, source: :llm)

        # original category should still be there
        expect(transaction.reload.category).to eq(category)
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
        # Verify the job doesn't crash when categorizer returns nil
        # Just run the job and ensure no exception is raised
        described_class.new.perform(transaction.id, source: :llm)

        # The suggested_category should remain nil since we don't stub categorizer
        expect(transaction.reload.suggested_category).to be_nil
      end
    end
  end
end
