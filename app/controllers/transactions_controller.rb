class TransactionsController < ApplicationController
  def index
    @month = resolve_month(params[:year], params[:month])
    @range = @month.beginning_of_month..@month.end_of_month

    tx = Transaction.where(date: @range)

    @income = tx.where("amount > 0").sum(:amount)
    @expenses = tx.where("amount < 0").sum(:amount).abs
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

    @by_category = tx.select("coalesce(confirmed_category, suggested_category)")
      .where("amount < 0")
      .group("coalesce(confirmed_category, suggested_category)")
      .sum(:amount)
  end

  private

  def resolve_month(year, month)
    if year.present? && month.present?
      Date.new(year.to_i, month.to_i, 1)
    else
      Date.current.beginning_of_month
    end
  rescue ArgumentError
    Date.current.beginning_of_month
  end
end
