class TransactionsController < ApplicationController
  def index
    @month = resolve_month(params[:year], params[:month])
    @range = @month.beginning_of_month..@month.end_of_month

    base_transactions = current_user.transactions.where(date: @range)

    @transactions =
      base_transactions
        .then { |rel| filter_by_category(rel) }
        .then { |rel| filter_by_search(rel) }
        .then { |rel| filter_by_amount_type(rel) }
        .then { |rel| filter_by_transaction_type(rel) }
        .order(date: :desc, id: :desc)

    @transaction_types = Transaction.transaction_types.keys
    Rails.logger.info "transaction_types=#{@transaction_types}"
    @categories =
      base_transactions
        .distinct
        .select("COALESCE(confirmed_category, suggested_category) as category")
        .order("category")
        .map(&:category)
  end


  private


  def filter_by_transaction_type(rel)
    return rel if params[:transaction_type].blank?

    rel.where(transaction_type: params[:transaction_type])
  end

  def filter_by_category(rel)
    return rel if params[:category].blank?

    rel.where(
      "COALESCE(confirmed_category, suggested_category) = ?",
      params[:category]
    )
  end

  def filter_by_search(rel)
    return rel if params[:q].blank?

    rel.where("description ILIKE ?", "%#{params[:q]}%")
  end

  def filter_by_amount_type(rel)
    case params[:type]
    when "expenses"
      rel.where("amount < 0")
    when "income"
      rel.where("amount > 0")
    else
      rel
    end
  end
end
