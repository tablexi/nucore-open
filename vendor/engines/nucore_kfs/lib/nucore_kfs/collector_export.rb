module NucoreKfs

  class CollectorExport
    require "date"

    def generate_export_header(batch_sequence_number)
      now = DateTime.now
      fy = (now.month < 6 ? now.year : now.year + 1).to_s
      ch_acc_code = "UC"
      org_code = "1348"
      tx_date = now.strftime("%Y-%m-%d")
      header_record_type = "HD"
      email = "null@uconn.edu"
      dep_contact_name = "Robert Stolarz"
      dep_name = "CORE"
      campus_address = "159 Discovery Dr, Storrs, CT"
      campus_code = "01"
      dep_phone_num = "8605551234" # TODO: get this right

      header_record = [
        fy.ljust(4),
        ch_acc_code.ljust(2),
        org_code.ljust(4),
        " " * 5,
        tx_date.ljust(10),
        header_record_type.ljust(2),
        batch_sequence_number.to_s.ljust(1),
        email.ljust(40),
        dep_contact_name.ljust(30),
        dep_name.ljust(30),
        campus_address.ljust(30),
        campus_code.ljust(2),
        dep_phone_num.ljust(10),
        " " * 2,
      ]

      return header_record.join("")
    end

    def generate_export_file(journal_rows)

      now = DateTime.now
      fy = (now.month < 6 ? now.year : now.year + 1).to_s
      ch_acc_code = "UC"
      org_code = "1348"
      tx_date = now.strftime("%Y-%m-%d")
      header_record_type = "HD"
      batch_sequence_number = "1" # TODO: needs to count up!
      email = "null@uconn.edu"
      dep_contact_name = "Robert Stolarz"
      dep_name = "CORE"
      campus_address = "159 Discovery Dr, Storrs, CT"
      campus_code = "01"
      dep_phone_num = "8605551234" # TODO: get this right

      output = ""
      batch_sequence_number = 1

      header_content = generate_export_header(batch_sequence_number)
      output << header_content << "\n"

      records = 0
      file_amt = 0

      # An increasing sequential number beginning with zero. Should be the same for each Debit(D) and Credit(C) entry.
      doc_num = 0

      journal_rows.each do |journal_row|
          od = journal_row.order_detail
          next unless journal_row.order_detail
          # TODO: move some of this logic to the model?
          prod = journal_row.order_detail.product
          facility_initials = od.facility.name.scan(/([A-Z])/).join
          date = od.created_at.strftime("%Y-%m-%d")
          aan_out = od.account.account_number
          fan_out = prod.facility_account.account_number

          raise "not a kfs account: #{aan_out}" unless aan_match = aan_out.match(/^KFS-(?<obj_code>\d{4})-(?<acct_num>\d{0,7})$/)
          raise "not a kfs account: #{fan_out}" unless fan_match = fan_out.match(/^KFS-(?<obj_code>\d{4})-(?<acct_num>\d{0,7})$/)

          bal_record_type = "AC"
          doc_type = "CLTR"
          orig_code = "CC"
          doc_from_char = "C"
          doc_num_as_str = doc_num.to_s
          desc = "#{facility_initials}|#{prod.name}|#{date}"[0..40]
          tx_dollar_amt = od.actual_cost.truncate(2).to_s("F")

          puts("tx_dollar_amt = #{tx_dollar_amt}")

          ref_field_1 = od.order_id.to_s
          ref_field_2 = od.id.to_s

          # make the LedgerEntry to track this export
          tracking_row = LedgerEntry.new(
              batch_sequence_number: batch_sequence_number,
              document_number: doc_num,
              exported_on: DateTime.now,
              journal_row: journal_row
          )
          tracking_row.kfs_status = "pending"
          # tracking_row.save!

          [
            { :match => aan_match, :code => "D" },
            { :match => fan_match, :code => "C" },
          ].each { |data|
            entry = [
              fy.ljust(4),
              ch_acc_code.ljust(2),
              data[:match][:acct_num].ljust(7),
              " " * 5,
              data[:match][:obj_code].ljust(4),
              " " * 3,
              bal_record_type.ljust(2),
              " " * 4,
              doc_type.ljust(4),
              orig_code.ljust(2),
              doc_from_char.ljust(1),
              doc_num_as_str.rjust(13, "0"),
              " " * 5,
              desc.ljust(40),
              " " * 1, # intentional
              tx_dollar_amt.rjust(20, "0"),
              data[:code].ljust(1),
              date.ljust(10),
              ref_field_1.ljust(10),
              " " * 10,
              ref_field_2.ljust(8),
              " " * 31,
            ]
            records += 1
            doc_num += 1
            file_amt += Float(tx_dollar_amt)

            output << entry.join("") << "\n"
          }
      end

      # Generate the trailer

      trailer_record_type = "TL"
      trailer_record = [
        " " * 25,
        trailer_record_type.ljust(2),
        " " * 19,
        records.to_s.rjust(5, "0"),
        " " * 41,
        file_amt.to_s.rjust(20, "0"),
      ]

      output << trailer_record.join("") << "\n"

      return output
    end
  end
end