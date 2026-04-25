module AsyncCategoryImprovement
  def self.enabled?
    ENV.fetch("ASYNC_CATEGORY_ENABLED", "true") == "true"
  end
end
