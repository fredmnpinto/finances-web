class ManualTransactionsController < ApplicationController
  def new
    @transaction = Transaction.new
    @categories = current_user.categories.order(:name).to_a
  end

  def create
    add_another = params.dig(:transaction, :add_another)
    @transaction = current_user.transactions.new(transaction_params_without_add_another)

    if @transaction.expense?
      @transaction.amount = -@transaction.amount.abs
    end

    if @transaction.save
      if add_another == "1"
        redirect_to new_manual_transaction_path, notice: "Transaction added successfully"
      else
        redirect_to transactions_path, notice: "Transaction added successfully"
      end
    else
      @categories = current_user.categories.order(:name).to_a
      render :new, status: :unprocessable_entity
    end
  end

  private

  def transaction_params_without_add_another
    params.require(:transaction).permit(:date, :description, :amount, :balance, :category_id, :source_file, :transaction_type)
  end
end
