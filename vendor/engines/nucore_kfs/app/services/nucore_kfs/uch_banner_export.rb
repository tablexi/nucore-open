module NucoreKfs

  class UchBannerExport

    def initialize(uch_journal_rows)
      @uch_journal_rows = uch_journal_rows
    end

    def generate_report(csv_file_path)
      CSV.open(csv_file_path, "wb") do |csv|
        keys = @uch_journal_rows.first.keys
        csv << keys
        @uch_journal_rows.each do |hash|
          csv << hash.values_at(*keys)
        end
      end
    end

    def to_csv()
      # attributes = @uch_journal_rows.first.attributes
      attributes = %w{id journal_id order_detail}
      puts("attributes = #{attributes}")
  
      CSV.generate(headers: true) do |csv|
        csv << attributes
  
        @uch_journal_rows.each do |row|
          puts("row = #{row}")
          csv << attributes.map{ |attr| row.send(attr) }
        end
      end
    end
    
  end
end
