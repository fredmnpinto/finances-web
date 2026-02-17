class TransactionsController < ApplicationController
  def index
    @month = resolve_month(params[:year], params[:month])
    @range = @month.beginning_of_month..@month.end_of_month

    base_transactions = current_user.transactions.where(date: @range)
    @category_confirmation_filter = params[:category_confirmation_filter] || "unconfirmed"

    filtered =
      base_transactions
        .then { |rel| filter_by_category(rel) }
        .then { |rel| filter_by_search(rel) }
        .then { |rel| filter_by_amount_type(rel) }
        .then { |rel| filter_by_transaction_type(rel) }
        .order(date: :desc, id: :desc)

    @transactions =
      filtered
        .then { |rel| filter_by_category_confirmation_filter(rel) }

    @transaction_types = Transaction.transaction_types.keys
    Rails.logger.info "transaction_types=#{@transaction_types}"
    @categories =
      base_transactions
        .distinct
        .select("COALESCE(confirmed_category, suggested_category) as category")
        .order("category")
        .map(&:category)
  end

  def categories
    @categories =
      current_user.transactions
        .where.not(confirmed_category: nil)
        .distinct
        .order(:confirmed_category)
        .pluck(:confirmed_category)

    render json: @categories
  end

  def confirm_category
    @transaction = current_user.transactions.find(params[:id])
    category = params[:category].presence || @transaction.suggested_category

    if @transaction.update(
         confirmed_category: category,
         confirmed_category_at: Time.current
       )
      redirect_to transactions_path(return_params), notice: "Category confirmed"
    else
      redirect_to transactions_path(return_params), alert: "Failed to confirm category"
    end
  end

  def bulk_update_categories
    transaction_ids = params[:transaction_ids].presence || []
    category = params[:category]
    action_type = params[:action_type]

    if transaction_ids.blank?
      redirect_to transactions_path(return_params), alert: "No transactions selected"
      return
    end

    ids_array = transaction_ids.split(",")

    if action_type == "confirm"
      updated_count = 0
      ids_array.each do |id|
        tx = current_user.transactions.find_by(id: id)
        if tx&.suggested_category
          tx.update(confirmed_category: tx.suggested_category, confirmed_category_at: Time.current)
          updated_count += 1
        end
      end
      redirect_to transactions_path(return_params), notice: "Confirmed #{updated_count} transaction(s)"
    elsif category.blank?
      redirect_to transactions_path(return_params), alert: "No category specified"
    else
      updated_count =
        current_user.transactions
          .where(id: ids_array)
          .update_all(
            confirmed_category: category,
            confirmed_category_at: Time.current
          )

      redirect_to transactions_path(return_params),
                  notice: "Updated #{updated_count} transaction(s)"
    end
  end

  def confirm_all_suggested
    @month = resolve_month(params[:year], params[:month])
    @range = @month.beginning_of_month..@month.end_of_month

    updated_count =
      current_user.transactions
        .where(date: @range)
        .where.not(suggested_category: nil)
        .where(confirmed_category: nil)
        .update_all(
          "confirmed_category = suggested_category,
           confirmed_category_at = #{Transaction.connection.quote(Time.current)}"
        )

    redirect_to transactions_path(return_params),
                notice: "Confirmed #{updated_count} suggested categories"
  end

  private

  def return_params
    { year: params[:year], month: params[:month], category_confirmation_filter: @category_confirmation_filter }
  end

  helper_method :return_params

  def filter_by_category_confirmation_filter(rel)
    case @category_confirmation_filter
    when "unconfirmed"
      rel.where(confirmed_category: nil)
    when "confirmed"
      rel.where.not(confirmed_category: nil)
    else
      rel
    end
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
