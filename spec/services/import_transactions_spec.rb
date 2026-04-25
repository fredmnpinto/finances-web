require 'rails_helper'

RSpec.describe ImportTransactions do
  let(:user) { create(:user) }
  let(:import_service) { described_class.new(user) }

  describe '#call' do
    let(:file) { fixture_file_upload('test.csv', 'text/csv') }
    let(:category_recommender) { instance_double(CategoryRecommender) }
    let(:spreadsheet) { instance_double(Roo::Excelx) }
    let(:sheet) { instance_double(Roo::Excelx) }

    before do
      Transaction.delete_all
      allow(CategoryRecommender).to receive(:new).with(user).and_return(category_recommender)
      allow(Roo::Spreadsheet).to receive(:open).and_return(spreadsheet)
      allow(spreadsheet).to receive(:sheet).with(0).and_return(sheet)
    end

    it 'raises error when file path is invalid' do
      allow(Roo::Spreadsheet).to receive(:open).and_raise(StandardError.new("Invalid path"))

      expect { import_service.call(file) }.to raise_error(StandardError)
    end

    context 'with valid spreadsheet' do
      before do
        allow(category_recommender).to receive(:categorize).and_return(
          { category: nil, confidence: 0, source: 'none' }
        )
        allow(sheet).to receive(:row).with(13).and_return(
          [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
        )
        allow(sheet).to receive(:row).with(14).and_return(
          [ '15-01-2024', '15-01-2024', 'Test Expense', '-50.00', '1000.00' ]
        )
        allow(sheet).to receive(:row).with(15).and_return(
          [ '16-01-2024', '16-01-2024', 'Test Income', '2000.00', '3000.00' ]
        )
        allow(sheet).to receive(:last_row).and_return(15)
        allow(sheet).to receive(:first_row).and_return(1)
        (1..12).each { |i| allow(sheet).to receive(:row).with(i).and_return([ 'some', 'other', 'data' ]) }
      end

      it 'imports transactions from spreadsheet' do
        expect { import_service.call(file) }.to change(Transaction, :count).by(2)
      end

      it 'sets transaction type based on amount' do
        import_service.call(file)

        expense = Transaction.order(:transaction_date).first
        income = Transaction.order(:transaction_date).last

        expect(expense.transaction_type).to eq('expense')
        expect(income.transaction_type).to eq('income')
      end

      it 'sets source_file on transactions' do
        import_service.call(file)

        expect(Transaction.first.source_file).to eq('test.csv')
      end

      it 'calls categorizer for each transaction' do
        expect(category_recommender).to receive(:categorize).twice
        import_service.call(file)
      end

      it 'saves transaction even if categorizer fails' do
        expect(category_recommender).to receive(:categorize).and_raise(StandardError)

        expect {
          import_service.call(file)
        }.to change(Transaction, :count).by(2)
      end

      it 'does not import transactions that already exist' do
        import_service.call(file)
        expect { import_service.call(file) }.not_to change(Transaction, :count)
      end
    end
  end

  describe '#find_header_row' do
    let(:file) { fixture_file_upload('test.csv', 'text/csv') }
    let(:spreadsheet) { instance_double(Roo::Excelx) }
    let(:sheet) { instance_double(Roo::Excelx) }

    before do
      allow(Roo::Spreadsheet).to receive(:open).and_return(spreadsheet)
      allow(spreadsheet).to receive(:sheet).with(0).and_return(sheet)
    end

    it 'finds header row at row 1' do
      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(10)
      allow(sheet).to receive(:row).with(1).and_return([ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ])
      allow(sheet).to receive(:row).with(2).and_return([ '16-01-2024', '16-01-2024', 'Test', '100.00', '1000.00' ])
      (3..10).each { |i| allow(sheet).to receive(:row).with(i).and_return([]) }

      result = import_service.send(:parse_xls, file)
      expect(result.length).to eq(1)
    end

    it 'finds header row at row 13 (like BPI exports)' do
      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(89)
      allow(sheet).to receive(:row).with(13).and_return([ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ])
      allow(sheet).to receive(:row).with(14).and_return([ '16-01-2024', '16-01-2024', 'Test', '100.00', '1000.00' ])
      (1..12).each { |i| allow(sheet).to receive(:row).with(i).and_return([ 'some', 'other', 'data' ]) }
      (15..89).each { |i| allow(sheet).to receive(:row).with(i).and_return([]) }

      result = import_service.send(:parse_xls, file)
      expect(result.length).to eq(1)
    end

    it 'finds header row at row 5' do
      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(20)
      allow(sheet).to receive(:row).with(5).and_return([ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ])
      allow(sheet).to receive(:row).with(6).and_return([ '16-01-2024', '16-01-2024', 'Test', '100.00', '1000.00' ])
      [ 1, 2, 3, 4 ].each { |i| allow(sheet).to receive(:row).with(i).and_return([ 'some', 'other', 'data' ]) }
      (7..20).each { |i| allow(sheet).to receive(:row).with(i).and_return([]) }

      result = import_service.send(:parse_xls, file)
      expect(result.length).to eq(1)
    end
  end

  describe '#parse_xls' do
    let(:file) { fixture_file_upload('test.csv', 'text/csv') }
    let(:spreadsheet) { instance_double(Roo::Excelx) }
    let(:sheet) { instance_double(Roo::Excelx) }

    before do
      allow(Roo::Spreadsheet).to receive(:open).and_return(spreadsheet)
      allow(spreadsheet).to receive(:sheet).with(0).and_return(sheet)
    end

    it 'uses 1-based row indexing correctly' do
      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', 'Test', '100.00', '1000.00' ]
      )

      result = import_service.send(:parse_xls, file)
      expect(result.first[:transaction_date].year).to eq(2024)
    end
  end

  describe '#parse_date' do
    it 'returns Date objects unchanged' do
      date = Date.new(2024, 1, 15)
      expect(import_service.send(:parse_date, date)).to eq(date)
    end

    it 'parses string dates with format dd-mm-yyyy' do
      expect(import_service.send(:parse_date, '15-01-2024')).to eq(Date.new(2024, 1, 15))
    end

    it 'returns nil for invalid date strings' do
      expect(import_service.send(:parse_date, 'invalid')).to be_nil
    end

    it 'handles numeric excel dates' do
      result = import_service.send(:parse_date, 45305)
      expect(result).to be_a(Date)
    end

    it 'returns nil for nil input' do
      expect(import_service.send(:parse_date, nil)).to be_nil
    end
  end

  describe '#parse_amount' do
    it 'returns numeric values unchanged' do
      expect(import_service.send(:parse_amount, 100.50)).to eq(100.50)
    end

    it 'parses string amounts with comma separator' do
      expect(import_service.send(:parse_amount, '100,50')).to eq(100.5)
    end

    it 'parses string amounts with currency symbols' do
      expect(import_service.send(:parse_amount, '€100,50')).to eq(100.5)
    end

    it 'converts other types to float' do
      expect(import_service.send(:parse_amount, '50')).to eq(50.0)
    end

    it 'returns nil for nil input' do
      expect(import_service.send(:parse_amount, nil)).to be_nil
    end
  end

  describe '#determine_type' do
    it 'returns :income for positive amounts' do
      expect(import_service.send(:determine_type, 100.00)).to eq(:income)
    end

    it 'returns :expense for negative amounts' do
      expect(import_service.send(:determine_type, -50.00)).to eq(:expense)
    end
  end

  describe 'applies category rules from CategoryRecommender' do
    let(:file) { fixture_file_upload('test.csv', 'text/csv') }
    let(:spreadsheet) { instance_double(Roo::Excelx) }
    let(:sheet) { instance_double(Roo::Excelx) }
    let(:category_test_user) { create(:user) }

    before do
      Transaction.where(user: category_test_user).delete_all
      Category.where(user: category_test_user).delete_all
      # Create categories that match CategoryRecommender rules
      create(:category, user: category_test_user, name: "Salary")
      create(:category, user: category_test_user, name: "Food")
      create(:category, user: category_test_user, name: "Transport")
      create(:category, user: category_test_user, name: "Utilities")

      # Allow actual file parsing
      allow(Roo::Spreadsheet).to receive(:open).and_return(spreadsheet)
      allow(spreadsheet).to receive(:sheet).with(0).and_return(sheet)

      # CRITICAL: We need to prevent the outer describe's stub from taking effect
      # Reset ALL CategoryRecommender.new stubs first
      allow(CategoryRecommender).to receive(:new).and_call_original
    end

    # Override to specifically use our test user
    subject(:import_service) { described_class.new(category_test_user) }

    it 'matches "salary" description to Salary category' do
      # Use a unique description to find our specific transaction
      test_description = 'SALARY CLOUDCARE TEST UNIQUE'

      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', test_description, '2500.00', '1000.00' ]
      )

      import_service.call(file)

      # Query specifically for our transaction by description
      transaction = Transaction.where(user: category_test_user, description: test_description).first!
      expect(transaction.suggested_category.name).to eq('Salary')
    end

    it 'matches "ordenado" description to Salary category' do
      test_description = 'ORDENADO JANEIRO TEST'

      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', test_description, '2500.00', '1000.00' ]
      )

      import_service.call(file)

      transaction = Transaction.where(user: category_test_user, description: test_description).first!
      expect(transaction.suggested_category.name).to eq('Salary')
    end

    it 'matches "continente" description to Food category' do
      test_description = 'CONTINENTE TEST'

      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', test_description, '-45.00', '1000.00' ]
      )

      import_service.call(file)

      transaction = Transaction.where(user: category_test_user, description: test_description).first!
      expect(transaction.suggested_category.name).to eq('Food')
    end

    it 'matches "pingo doce" description to Food category' do
      test_description = 'PINGO DOCE TEST'

      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', test_description, '-30.00', '1000.00' ]
      )

      import_service.call(file)

      transaction = Transaction.where(user: category_test_user, description: test_description).first!
      expect(transaction.suggested_category.name).to eq('Food')
    end

    it 'matches "uber" description to Transport category' do
      test_description = 'UBER TRIP TEST'

      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', test_description, '-15.00', '1000.00' ]
      )

      import_service.call(file)

      transaction = Transaction.where(user: category_test_user, description: test_description).first!
      expect(transaction.suggested_category.name).to eq('Transport')
    end

    it 'matches "bolt" description to Transport category' do
      test_description = 'BOLT TEST'

      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', test_description, '-12.00', '1000.00' ]
      )

      import_service.call(file)

      transaction = Transaction.where(user: category_test_user, description: test_description).first!
      expect(transaction.suggested_category.name).to eq('Transport')
    end

    it 'matches "edp" description to Utilities category' do
      test_description = 'EDP TEST'

      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', test_description, '-80.00', '1000.00' ]
      )

      import_service.call(file)

      transaction = Transaction.where(user: category_test_user, description: test_description).first!
      expect(transaction.suggested_category.name).to eq('Utilities')
    end

    it 'matches "vodafone" description to Utilities category' do
      test_description = 'VODAFONE TEST'

      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', test_description, '-35.00', '1000.00' ]
      )

      import_service.call(file)

      transaction = Transaction.where(user: category_test_user, description: test_description).first!
      expect(transaction.suggested_category.name).to eq('Utilities')
    end
  end

  describe 'async categorization behavior' do
    let(:file) { fixture_file_upload('test.csv', 'text/csv') }
    let(:spreadsheet) { instance_double(Roo::Excelx) }
    let(:sheet) { instance_double(Roo::Excelx) }
    let(:category_test_user) { create(:user, email: "test#{SecureRandom.hex(8)}@example.com") }

    before do
      Transaction.where(user: category_test_user).delete_all
      Category.where(user: category_test_user).delete_all
      Category.find_or_create_by!(user: category_test_user, name: "Salary")
      Category.find_or_create_by!(user: category_test_user, name: "Food")

      allow(Roo::Spreadsheet).to receive(:open).and_return(spreadsheet)
      allow(spreadsheet).to receive(:sheet).with(0).and_return(sheet)
      allow(CategoryRecommender).to receive(:new).and_call_original
    end

    subject(:import_service) { described_class.new(category_test_user) }

    context 'when async improvement is enabled' do
      before do
        allow(AsyncCategoryImprovement).to receive(:enabled?).and_return(true)
      end

      it 'schedules CategorizeTransactionJob when rules return nil' do
        test_description = 'UNKNOWN VENDOR NO RULES'

        allow(sheet).to receive(:first_row).and_return(1)
        allow(sheet).to receive(:last_row).and_return(2)
        allow(sheet).to receive(:row).with(1).and_return(
          [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
        )
        allow(sheet).to receive(:row).with(2).and_return(
          [ '15-01-2024', '15-01-2024', test_description, '-50.00', '1000.00' ]
        )

        expect(CategorizeTransactionJob).to receive(:perform_later)
        import_service.call(file)
      end

      it 'does NOT schedule job when rules match' do
        # Create a transaction that matches the "salary" rule
        test_description = 'CLOUDFLARE PORTUGAL SALARY'

        allow(sheet).to receive(:first_row).and_return(1)
        allow(sheet).to receive(:last_row).and_return(2)
        allow(sheet).to receive(:row).with(1).and_return(
          [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
        )
        allow(sheet).to receive(:row).with(2).and_return(
          [ '15-01-2024', '15-01-2024', test_description, '2500.00', '1000.00' ]
        )

        expect(CategorizeTransactionJob).not_to receive(:perform_later)
        import_service.call(file)

        # Verify transaction was categorized by rules
        transaction = Transaction.where(user: category_test_user, description: test_description).first!
        expect(transaction.suggested_category.name).to eq('Salary')
      end
    end

    context 'when async improvement is disabled' do
      before do
        allow(AsyncCategoryImprovement).to receive(:enabled?).and_return(false)
      end

      it 'does NOT schedule job when feature flag is disabled' do
        test_description = 'UNKNOWN VENDOR NO RULES'

        allow(sheet).to receive(:first_row).and_return(1)
        allow(sheet).to receive(:last_row).and_return(2)
        allow(sheet).to receive(:row).with(1).and_return(
          [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
        )
        allow(sheet).to receive(:row).with(2).and_return(
          [ '15-01-2024', '15-01-2024', test_description, '-50.00', '1000.00' ]
        )

        expect(CategorizeTransactionJob).not_to receive(:perform_later)
        import_service.call(file)
      end
    end

    it 'import continues immediately after scheduling job (non-blocking)' do
      allow(AsyncCategoryImprovement).to receive(:enabled?).and_return(true)
      test_description = 'UNKNOWN VENDOR NO RULES'

      allow(sheet).to receive(:first_row).and_return(1)
      allow(sheet).to receive(:last_row).and_return(2)
      allow(sheet).to receive(:row).with(1).and_return(
        [ 'Data Mov.', 'Data Valor', 'Descrição do Movimento', 'Valor em EUR', 'Saldo em EUR' ]
      )
      allow(sheet).to receive(:row).with(2).and_return(
        [ '15-01-2024', '15-01-2024', test_description, '-50.00', '1000.00' ]
      )

      # Import should complete immediately - verify job is scheduled via perform_later
      expect(CategorizeTransactionJob).to receive(:perform_later)
      result = import_service.call(file)
      expect(result).to eq(1) # Should return count immediately
    end
  end
end
