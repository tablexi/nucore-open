# desc "Explaining what the task does"
# task :nucore_kfs do
#   # Task goes here
# end


desc "Generate an export file for the KFS Collector"
task :kfs_collector_export => :environment do

  all_journals = Journal.all

  rows_to_export = []

  all_journals.each do |journal|
    journal.journal_rows.each do |journal_row|
      od = journal_row.order_detail
      next unless journal_row.order_detail
      prod = journal_row.order_detail.product
      aan_out = od.account.account_number
      fan_out = prod.facility_account.account_number

      aan_match = aan_out.match(/^KFS-(?<obj_code>\d{4})-(?<acct_num>\d{0,7})$/)
      fan_match = fan_out.match(/^KFS-(?<obj_code>\d{4})-(?<acct_num>\d{0,7})$/)

      if !aan_match
        # logger.info("for id #{od.id}: order account not a kfs account: #{aan_out}")
        puts("for id #{od.id}: order account not a kfs account: #{aan_out}")
      elsif !fan_match
        # logger.info("for id #{od.id}: recharge account not a kfs account: #{fan_out}")
        puts("for id #{od.id}: recharge account not a kfs account: #{fan_out}")
      elsif LedgerEntry.where(journal_row_id: journal_row.id).empty?
        rows_to_export.push(journal_row)
      else
        # logger.info("LedgerEntry already exists for journal_row_id = #{journal_row.id}")
        puts("LedgerEntry already exists for journal_row_id = #{journal_row.id}")
      end
    end
  end

  exporter = NucoreKfs::CollectorExport.new
  export_content = exporter.generate_export_file(rows_to_export)

  # puts(export_content)
  export_file = "/vagrant/workspace/kfs-out.dat"
  File.open(export_file, "w") { |file| file.write export_content }

end
