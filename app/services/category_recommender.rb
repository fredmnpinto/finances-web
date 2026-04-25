class CategoryRecommender
  RULES = [
    { category: "Salary", confidence: 1.0, keywords: [ "cloudflare portugal", "salary", "ordenado" ] },
    { category: "Freelance", confidence: 0.9, keywords: [ "freelance", "freelancer", "upwork", "fiverr" ] },
    { category: "Investments", confidence: 1.0, keywords: [ "invest", "xtb", "degiro", "etrade" ] },
    { category: "Refunds", confidence: 0.9, keywords: [ "reembolso", "refund", "devolucao" ] },
    { category: "Housing", confidence: 1.0, keywords: [ "renda", "rental", "renting", "mortgage", "habitacao" ] },
    { category: "Food", confidence: 0.95, keywords: [ "continente", "pingo doce", "lidl", "aldi", "auchan", "intermarche", "mercadona", "glovo", "talhos", "minipreco", "el corte ingles" ] },
    { category: "Transport", confidence: 0.95, keywords: [ "uber", "bolt", "free now", "cp", "metro", "prio", "posto bp", "galp", "shell", "bp" ] },
    { category: "Utilities", confidence: 1.0, keywords: [ "gold energy", "edp", "vodafone", "meo", "nos", "internet", "luz", "agua" ] },
    { category: "Health", confidence: 1.0, keywords: [ "farmacia", "well's", "hops privado", "farm ferreira", "hospital", "clinica" ] },
    { category: "Insurance", confidence: 1.0, keywords: [ "allianz", "fidelidade", "realvseguros", "seguros" ] },
    { category: "Entertainment", confidence: 0.9, keywords: [ "cinema", "theatre", "theater", "netflix", "spotify", "playstation", "xbox", "steam" ] },
    { category: "Shopping", confidence: 0.9, keywords: [ "amazon", "amzn", "aliexpress", "ebay", "shein", "sephora", "primor", "el corte ingles", "kiko milano", "cult beauty", "casa china", "zara", "h&m" ] },
    { category: "Self-care", confidence: 0.8, keywords: [ "salon", "cabeleireiro", "barbearia", "spa", "beauty" ] },
    { category: "Subscriptions", confidence: 0.95, keywords: [ "spotify", "netflix", "youtube", "prime video", "icloud", "adobe", "microsoft", "github" ] },
    { category: "Savings", confidence: 1.0, keywords: [ "poupanca", "deposito", "mobilizacao" ] },
    { category: "Taxes", confidence: 1.0, keywords: [ "imposto", "fora zona euro", "conversao de moeda", "cred.div.", "taxa" ] }
  ].freeze

  def initialize(user)
    @user = user
  end

  def categorize(description:, amount:, source: :all)
    case source
    when :rules
      apply_rules(description) # returns nil if no match
    when :llm
      ollama_categorize(description, amount)
    else # :all (default, backward compatible)
      rule_result = apply_rules(description)
      return rule_result if rule_result
      ollama_categorize(description, amount)
    end
  end

  private

  def apply_rules(description)
    normalized = normalize(description)

    RULES.each do |rule|
      rule[:keywords].each do |keyword|
        if normalized.include?(keyword.downcase)
          return {
            category: find_category!(rule[:category]),
            confidence: rule[:confidence],
            source: "rule"
          }
        end
      end
    end

    nil
  end

  def ollama_categorize(description, amount)
    client = OllamaClient.new
    result = client.categorize(description: description, amount: amount)

    category = find_category(result["category"])

    {
      category: category,
      confidence: result["confidence"].to_f,
      source: "llm"
    }
  end

  def normalize(text)
    text
      .gsub(/^COMPRA\s+ELEC\s+\d+\/\d+\s*/, "")
      .downcase
  end

  def find_category(name)
    @user.categories.find_by(name: name)
  end

  def find_category!(name)
    category = find_category(name)
    return category if category

    @user.categories.find_by!(name: fallback_category(name))
  end

  def fallback_category(suggested_name)
    return "Other Expenses" if suggested_name =~ /expense|other/i
    return "Other Income" if suggested_name =~ /income|other/i
    return "Savings" if suggested_name =~ /savings/i

    "Other Expenses"
  end
end
