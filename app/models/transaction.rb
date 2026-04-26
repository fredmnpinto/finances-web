class Transaction < ApplicationRecord
  # On create: schedule job if suggested_category is nil (rules couldn't find one)
  after_commit :enqueue_categorize_job, on: :create,
    if: -> { suggested_category.nil? && AsyncCategoryImprovement.enabled? }

  # On update: schedule job if suggested_category changed TO nil
  after_commit :enqueue_categorize_job, on: :update,
    if: -> {
      saved_change_to_suggested_category_id? &&
      suggested_category.nil? &&
      AsyncCategoryImprovement.enabled?
    }

  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :suggested_category, class_name: "Category", optional: true

  enum :transaction_type, { expense: 0, income: 1, savings: 2 }

  validates :user, presence: true
  validates :amount, presence: true, numericality: true
  validates :description, presence: true
  validates :transaction_date, presence: true
  validates :transaction_type, presence: true

  private

  def enqueue_categorize_job
    CategorizeTransactionJob.perform_later(id, source: :llm)
  end
end
