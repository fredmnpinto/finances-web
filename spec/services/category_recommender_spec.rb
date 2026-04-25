require 'rails_helper'

RSpec.describe CategoryRecommender do
  # Use a sequence to generate unique users for each test
  let(:user) { create(:user, email: "test#{SecureRandom.hex(8)}@example.com") }
  let(:categorizer) { described_class.new(user) }

  before do
    # Create categories that match the CategoryRecommender rules
    # Use find_or_create to avoid uniqueness violations
    Category.find_or_create_by!(user: user, name: "Salary")
    Category.find_or_create_by!(user: user, name: "Food")
    Category.find_or_create_by!(user: user, name: "Transport")
    Category.find_or_create_by!(user: user, name: "Utilities")
    Category.find_or_create_by!(user: user, name: "Investments")
    Category.find_or_create_by!(user: user, name: "Other Expenses")
    Category.find_or_create_by!(user: user, name: "Other Income")
  end

  describe '#categorize with source parameter' do
    context 'source: :rules' do
      it 'returns match when keywords present in description' do
        result = categorizer.categorize(
          description: "cloudflare portugal salary payment",
          amount: 2500.00,
          source: :rules
        )

        expect(result).not_to be_nil
        expect(result[:category].name).to eq("Salary")
        expect(result[:source]).to eq("rule")
      end

      it 'returns nil when no rules match (never returns fallback)' do
        result = categorizer.categorize(
          description: "UNKNOWN MERCHANT XYZ 123",
          amount: 25.00,
          source: :rules
        )

        expect(result).to be_nil
      end

      it 'matches "continente" to Food category' do
        result = categorizer.categorize(
          description: "CONTINENTE SUPERMARKET",
          amount: -45.00,
          source: :rules
        )

        expect(result).not_to be_nil
        expect(result[:category].name).to eq("Food")
      end

      it 'matches "uber" to Transport category' do
        result = categorizer.categorize(
          description: "UBER TRIP",
          amount: -15.00,
          source: :rules
        )

        expect(result).not_to be_nil
        expect(result[:category].name).to eq("Transport")
      end
    end

    context 'source: :llm' do
      let(:ollama_client) { instance_double(OllamaClient) }

      before do
        allow(OllamaClient).to receive(:new).and_return(ollama_client)
      end

      it 'calls OllamaClient and returns result' do
        allow(ollama_client).to receive(:categorize).with(
          description: "Some merchant",
          amount: 25.00
        ).and_return({ "category" => "Food", "confidence" => 0.7 })

        result = categorizer.categorize(
          description: "Some merchant",
          amount: 25.00,
          source: :llm
        )

        expect(result).not_to be_nil
        expect(result[:category].name).to eq("Food")
        expect(result[:source]).to eq("llm")
        expect(result[:confidence]).to eq(0.7)
      end
    end

    context 'source: :all (default)' do
      let(:ollama_client) { instance_double(OllamaClient) }

      before do
        allow(OllamaClient).to receive(:new).and_return(ollama_client)
      end

      it 'falls back to LLM when rules return nil' do
        allow(ollama_client).to receive(:categorize).with(
          description: "Unknown merchant",
          amount: 25.00
        ).and_return({ "category" => "Food", "confidence" => 0.6 })

        result = categorizer.categorize(
          description: "Unknown merchant",
          amount: 25.00
          # source: :all is default
        )

        expect(result).not_to be_nil
        expect(result[:source]).to eq("llm")
      end

      it 'returns rule match immediately without calling LLM when rules match' do
        result = categorizer.categorize(
          description: "uber trip downtown",
          amount: -15.00
        )

        expect(result).not_to be_nil
        expect(result[:source]).to eq("rule")
        # LLM should not be called
        expect(ollama_client).not_to receive(:categorize)
      end

      it 'is backward compatible - default behavior returns categorization' do
        allow(ollama_client).to receive(:categorize).with(
          description: "test",
          amount: 10.00
        ).and_return({ "category" => "Other Expenses", "confidence" => 0.5 })

        result = categorizer.categorize(description: "test", amount: 10.00)

        expect(result).not_to be_nil
        expect(result[:category]).not_to be_nil
      end
    end
  end
end
