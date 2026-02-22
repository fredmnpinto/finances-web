class ManualTransactionsController < ApplicationController
  def new
    @transaction = Transaction.new
    @categories = current_user.categories.order(:name).to_a
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)
    @transaction.transaction_type = determine_type(@transaction.amount)

    if @transaction.save
      redirect_to transactions_path, notice: "Transaction added successfully"
    else
      @categories = current_user.categories.order(:name).to_a
      render :new, status: :unprocessable_entity
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:date, :description, :amount, :balance, :category_id, :source_file)
  end

  def determine_type(amount)
    return :income if amount.to_f.positive?
    :expense
  end
end
