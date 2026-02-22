class ImportTransactions
  COLUMN_MAP = {
    "Data Mov." => :date,
    "Data Valor" => :value_date,
    "Descrição do Movimento" => :description,
    "Valor em EUR" => :amount,
    "Saldo em EUR" => :balance
  }.freeze

  def initialize(user)
    @user = user
  end

  def call(file)
    rows = parse_xls(file)
    imported_count = 0

    rows.each do |row|
      next if row[:date].nil? || row[:description].nil? || row[:amount].nil?

      transaction = @user.transactions.find_or_initialize_by(
        date: row[:date],
        description: row[:description],
        amount: row[:amount],
        balance: row[:balance]
      )

      if transaction.new_record?
        transaction.source_file = file.original_filename
        transaction.transaction_type = determine_type(row[:amount])

        result = categorizer.categorize(
          description: row[:description],
          amount: row[:amount]
        )

        transaction.suggested_category = result[:category]

        transaction.save!
        imported_count += 1
      end
    end

    imported_count
  end

  private

  def categorizer
    @categorizer ||= CategoryRecommender.new(@user)
  end

  def parse_xls(file)
    spreadsheet = Roo::Spreadsheet.open(file.path, extension: :xlsx)
    sheet = spreadsheet.sheet(0)

    header_row = find_header_row(sheet)
    headers = sheet.row(header_row).map { |h| COLUMN_MAP[h] || h }
    data_rows = ((header_row + 1)..sheet.last_row).map { |i| sheet.row(i) }

    data_rows.filter_map do |row|
      next if row.compact.empty?

      hash = headers.zip(row).to_h
      hash[:date] = parse_date(hash[:date])
      hash[:value_date] = parse_date(hash[:value_date])
      hash[:amount] = parse_amount(hash[:amount])
      hash[:balance] = parse_amount(hash[:balance])

      hash
    end
  end

  def find_header_row(sheet)
    COLUMN_MAP.keys.each do |header|
      (sheet.first_row..sheet.last_row).each do |row|
        return row if sheet.row(row).include?(header)
      end
    end
    1
  end

  def parse_date(value)
    return nil if value.nil?

    case value
    when Date then value
    when String
      Date.strptime(value, "%d-%m-%Y") rescue nil
    else
      Date.parse(value.to_s) rescue nil
    end
  end

  def parse_amount(value)
    return nil if value.nil?

    case value
    when Numeric then value
    when String
      value.gsub(/[^\d,-]/, "").tr(",", ".").to_f
    else
      value.to_f
    end
  end

  def determine_type(amount)
    return :income if amount.positive?
    return :savings if amount.to_s.match?(/poupanca|deposito|mobilizacao/i)
    :expense
  end
end
