class TransactionsController < ApplicationController
  def index
    range = Date.current.beginning_of_month..Date.current

    tx = Transaction.where(date: range)

    @income = tx.where("amount > 0").sum(:amount)
    @expenses = tx.where("amount < 0").sum(:amount).abs
    @net = @income - @expenses

    @avg_daily = @expenses / Date.current.day
    @largest_expenses = tx.where("amount < 0")
                           .order(amount: :asc)
                           .limit(5)

    daily_spending_avg = @expenses / Date.current.day
    @expected_spend_this_month = daily_spending_avg * Date.current.day

    @by_category = tx.select("coalesce(confirmed_category, suggested_category)")
      .where("amount < 0")
      .group("coalesce(confirmed_category, suggested_category)")
      .sum(:amount)

    @categories = tx.select("unique coalesce(confirmed_category, suggested_category) as category")
  end
end
