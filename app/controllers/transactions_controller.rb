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
        .includes(:category, :suggested_category)

    @transaction_types = Transaction.transaction_types.keys
    @categories = current_user.categories.order(:name).to_a
  end

  def categories
    @categories = current_user.categories.order(:name).pluck(:name)
    render json: @categories
  end

  def confirm_category
    @transaction = current_user.transactions.find(params[:id])
    category = params[:category].presence || @transaction.suggested_category

    if @transaction.update(category: category)
      redirect_to transactions_path(return_params), notice: "Category confirmed"
    else
      redirect_to transactions_path(return_params), alert: "Failed to confirm category"
    end
  end

  def bulk_update_categories
    transaction_ids = params[:transaction_ids].presence || []
    category_id = params[:category_id]
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
          tx.update(category: tx.suggested_category)
          updated_count += 1
        end
      end
      redirect_to transactions_path(return_params), notice: "Confirmed #{updated_count} transaction(s)"
    elsif category_id.blank?
      redirect_to transactions_path(return_params), alert: "No category specified"
    else
      category = current_user.categories.find_by(id: category_id)
      if category.nil?
        redirect_to transactions_path(return_params), alert: "Category not found"
        return
      end

      updated_count =
        current_user.transactions
          .where(id: ids_array)
          .update_all(category_id: category.id)

      redirect_to transactions_path(return_params),
                  notice: "Updated #{updated_count} transaction(s)"
    end
  end

  def confirm_all_suggested
    @month = resolve_month(params[:year], params[:month])
    @range = @month.beginning_of_month..@month.end_of_month

    updated_count = 0
    current_user.transactions
      .where(date: @range)
      .where.not(suggested_category_id: nil)
      .where(category_id: nil)
      .find_each do |tx|
        tx.update(category: tx.suggested_category)
        updated_count += 1
      end

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
      rel.where(category_id: nil)
    when "confirmed"
      rel.where.not(category_id: nil)
    else
      rel
    end
  end

  def filter_by_transaction_type(rel)
    return rel if params[:transaction_type].blank?

    rel.where(transaction_type: params[:transaction_type])
  end

  def filter_by_category(rel)
    return rel if params[:category].blank?

    category = current_user.categories.find_by(name: params[:category])
    return rel unless category

    rel.where("COALESCE(category_id, suggested_category_id) = ?", category.id)
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
