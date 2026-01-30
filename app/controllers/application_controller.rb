class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes


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
