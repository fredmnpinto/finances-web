require 'rails_helper'

RSpec.describe AsyncCategoryImprovement do
  describe '.enabled?' do
    after do
      # Reset ENV after each test
      ENV.delete("ASYNC_CATEGORY_ENABLED")
    end

    it 'returns true by default when ENV is not set' do
      ENV.delete("ASYNC_CATEGORY_ENABLED")
      expect(described_class.enabled?).to eq(true)
    end

    it 'returns true when ENV is "true"' do
      ENV["ASYNC_CATEGORY_ENABLED"] = "true"
      expect(described_class.enabled?).to eq(true)
    end

    it 'returns false when ENV is "false"' do
      ENV["ASYNC_CATEGORY_ENABLED"] = "false"
      expect(described_class.enabled?).to eq(false)
    end

    it 'returns false for any other value' do
      ENV["ASYNC_CATEGORY_ENABLED"] = "0"
      expect(described_class.enabled?).to eq(false)

      ENV["ASYNC_CATEGORY_ENABLED"] = "disabled"
      expect(described_class.enabled?).to eq(false)
    end
  end
end
