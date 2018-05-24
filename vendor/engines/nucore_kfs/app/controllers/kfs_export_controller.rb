class KfsExportController < ApplicationController
  include CSVHelper
  def show
    @journal = Journal.find(params[:id])
    @journal_rows = @journal.journal_rows
    @journal.journal_rows.each do |journal_row|
      od = journal_row.order_detail
      next unless journal_row.order_detail
      next unless od.account.account_number.start_with? "KFS" # do we need this
      prod = journal_row.order_detail.product
      if !(prod.facility_account and prod.facility_account.account_number.start_with? "KFS") then
        flash[:error] = "ERROR: Couldn't determine where to return revenue for #{prod.facility.name}'s #{prod.name}"
        redirect_to facility_journals_path(current_facility)
        
      end
    end
    set_csv_headers("#{params[:id]}.csv")
  end
end
