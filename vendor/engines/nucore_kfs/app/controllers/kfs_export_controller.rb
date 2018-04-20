class KfsExportController < ApplicationController
  include CSVHelper
  def show
    @journal = Journal.find(params[:id])
    @journal_rows = @journal.journal_rows
    set_csv_headers("#{params[:id]}.csv")
  end
end
