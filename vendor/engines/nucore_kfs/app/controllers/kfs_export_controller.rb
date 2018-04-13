class KfsExportController < ApplicationController
  def show
    @journal = Journal.find(params[:id])
    @journal_rows = @journal.journal_rows
  end
end
