class CategorizeTransactionJob < ApplicationJob
  queue_as :categorization

  retry_on StandardError, attempts: 3, wait: :exponentially_longer

  discard_on ActiveJob::DeserializationError

  def perform(transaction_id, source: :llm)
    transaction = Transaction.find_by(id: transaction_id)
    return log_missed("Transaction #{transaction_id} not found")

    return if transaction.category_id.present?

    categorizer = CategoryRecommender.new(transaction.user)
    result = categorizer.categorize(
      description: transaction.description,
      amount: transaction.amount,
      source: source
    )

    return if result.nil?

    transaction.update!(suggested_category: result[:category])
    Rails.logger.info("Categorized transaction #{transaction_id} with #{result[:category].name} (source: #{result[:source]})")
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to update transaction #{transaction_id}: #{e.message}")
  end

  private

  def log_missed(message)
    Rails.logger.warn(message)
  end
end
