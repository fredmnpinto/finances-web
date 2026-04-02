class ManualTransactionsController < ApplicationController
  def new
    @transaction = Transaction.new
    @categories = current_user.categories.order(:name).to_a
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)

    if @transaction.expense?
      @transaction.amount = -@transaction.amount.abs
    end

    if @transaction.save
      redirect_to transactions_path, notice: "Transaction added successfully"
    else
      @categories = current_user.categories.order(:name).to_a
      render :new, status: :unprocessable_entity
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:date, :description, :amount, :balance, :category_id, :source_file, :transaction_type)
  end
end
