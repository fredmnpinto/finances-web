class OllamaClient
  DEFAULT_MODEL = "llama3.1"

  def initialize(url: nil, model: nil)
    @url = url || ENV.fetch("OLLAMA_URL", "http://localhost:11434")
    @model = model || ENV.fetch("OLLAMA_MODEL", DEFAULT_MODEL)
  end

  def categorize(description:, amount:)
    prompt = build_prompt(description, amount)

    response = client.generate(model: @model, prompt: prompt)
    parse_response(response["response"])
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Ollama response: #{e.message}"
    fallback_response
  rescue => e
    Rails.logger.error "Ollama error: #{e.message}"
    fallback_response
  end

  def available?
    client.tags.present?
  rescue => e
    Rails.logger.error "Ollama availability check failed: #{e.message}"
    false
  end

  private

  def client
    @client ||= ::Ollama::Client.new(base_url: @url)
  end

  def build_prompt(description, amount)
    <<~PROMPT
      You are categorizing bank transactions.

      Transaction:
      - Description: "#{normalize_description(description)}"
      - Amount: #{amount}

      Choose exactly ONE category from this list:
      #{category_list}

      Rules:
      - Income is positive amounts from salary, freelance, investments, or refunds
      - Transfers are money moved between accounts (use Savings if to savings account)
      - Subscriptions are recurring services (streaming, software)
      - Food is supermarket groceries
      - Eating Out should be categorized as Food
      - Housing includes rent, mortgage, home repairs
      - Transport includes gas, uber, public transit
      - If unsure, choose "Other Expenses"

      Confidence guidelines:
      - 0.9–1.0 → merchant is unambiguous
      - 0.6–0.8 → reasonable guess
      - 0.3–0.5 → weak signal
      - <0.3 → almost random guess

      Respond ONLY with valid JSON in this exact format:
      {"category": "<category>", "confidence": <number between 0 and 1>}
    PROMPT
  end

  def category_list
    @category_list ||= Category.category_groups.keys.map do |group|
      Category.where(category_group: group).pluck(:name)
    end.flatten.join(", ")
  end

  def normalize_description(text)
    text.gsub(/^COMPRA\s+ELEC\s+\d+\/\d+\s*/, "")
        .gsub(/\d+/, "")
        .gsub(/[^a-zA-Z\s]/, " ")
        .squeeze(" ")
        .strip
        .downcase
  end

  def parse_response(text)
    JSON.parse(text)
  rescue JSON::ParserError
    fallback_response
  end

  def fallback_response
    { "category" => "Other Expenses", "confidence" => 0.0 }
  end
end
