class DashboardController < ApplicationController
  def index
    @month = resolve_month(params[:year], params[:month])
    @range = @month.beginning_of_month..@month.end_of_month

    tx = current_user.transactions.where(date: @range)

    @income = tx.income.sum(:amount)
    @expenses = tx.expense.sum(:amount).abs
    @net = @income - @expenses

    @days_elapsed =
      if @month == Date.current.beginning_of_month
        Date.current.day
      else
        @month.end_of_month.day
      end

    @avg_daily = @days_elapsed.zero? ? 0 : @expenses / @days_elapsed
    @largest_expenses = tx.where("amount < 0")
                           .order(amount: :asc)
                           .limit(5)

    @by_category = tx.where("amount < 0")
      .joins("LEFT JOIN categories ON categories.id = COALESCE(transactions.category_id, transactions.suggested_category_id)")
      .group("categories.id, categories.name")
      .select("categories.id, categories.name, categories.color, categories.icon, SUM(transactions.amount) as total")
      .order("total ASC")
      .each_with_object({}) do |row, hash|
        key = row.name || "Uncategorized"
        hash[key] = row.total.abs
        hash["#{key}_color"] = row.color if row.color
        hash["#{key}_icon"] = row.icon if row.icon
      end
  end
end
