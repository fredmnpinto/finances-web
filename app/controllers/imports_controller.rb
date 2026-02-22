class ImportsController < ApplicationController
  def new
  end

  def create
    file = import_params[:file]

    if file.blank?
      redirect_to new_import_path, alert: "Please select a file"
      return
    end

    unless valid_file?(file)
      Rails.logger.error "Invalid file format"
      redirect_to new_import_path, alert: "Invalid file format. Please upload an XLS file."
      return
    end

    count = ImportTransactions.new(current_user).call(file)

    if count.positive?
      redirect_to transactions_path, notice: "Successfully imported #{count} transaction(s)"
    else
      redirect_to new_import_path, alert: "No new transactions were imported. They may already exist."
    end
  rescue => e
    Rails.logger.error "Error importing file: #{e.full_message}"
    redirect_to new_import_path, alert: "Error importing file: #{e}"
  end

  private

  def import_params
    params.permit(:file)
  end

  def valid_file?(file)
    [ ".xls", ".xlsx" ].include?(File.extname(file.original_filename).downcase)
  end
end
