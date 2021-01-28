module NucoreKfs

  class CollectorTransaction
    require "date"

    @@UCH_GLOBAL_DEBIT_ACCOUNT = 'KFS-4643530-1390'

    # Please reference the "Collector Batch Format" document for a complete
    # understanding of all the fields are formatting used here.

    def initialize(journal_row)
      @order_detail = journal_row.order_detail
      # TODO: move some of this logic to the model?
      @transaction_date = @order_detail.created_at.strftime("%Y-%m-%d")
      @product = @order_detail.product
      @facility_initials = @order_detail.facility.name.scan(/([A-Z])/).join
      @description = "|CORE|#{@facility_initials}|#{@transaction_date}|#{@product.name}"[0..39]
      @transaction_dollar_amount = @order_detail.actual_cost.truncate(2).to_s("F")
      @ref_field_1 = @order_detail.order_id.to_s
      @ref_field_2 = @order_detail.id.to_s
            
      # where to take the money (the purchaser)
      debit_account_string = get_debit_account(@order_detail)
      # where to send the money (the facility)
      credit_account_string = @product.facility_account.account_number
            
      # Parse account chartstrings (e.g., KFS-1234567-1234) to get account number and object code
      raise "invalid account format: #{debit_account_string}" unless debit_account_match = debit_account_string.match(/^(?<acct_type>\w{3})-(?<acct_num>\d{0,7})-(?<obj_code>\d{4})$/)
      raise "invalid account format: #{credit_account_string}" unless credit_account_match = credit_account_string.match(/^(?<acct_type>\w{3})-(?<acct_num>\d{0,7})-(?<obj_code>\d{4})$/)
                  
      @debit_account_number = debit_account_match[:acct_num]
      @credit_account_number = credit_account_match[:acct_num]
      @debit_object_code = debit_account_match[:obj_code]
      @credit_object_code = credit_account_match[:obj_code]

      @now = DateTime.now
      # TODO: There is a fiscal_year_begins setting that we should read and use here.
      # For now, we are just hardcoding the start of UConn's FY: July 1
      @fiscal_year = (@now.month < 7 ? @now.year : @now.year + 1).to_s

      @chart_accounts_code = "UC"
      @bal_record_type = "AC"
      @doc_type = "CLTR"
      @orig_code = "CC"
      @doc_from_char = "C"
    end

    def get_transaction_dollar_amount()
      return @transaction_dollar_amount.to_f
    end

    def create_credit_row_string()
      create_collector_row_string_helper(true)
    end

    def create_debit_row_string()
      create_collector_row_string_helper(false)
    end

    def get_debit_account(order_detail_row)
      account_number = order_detail_row.account.account_number
      is_uch = account_number.match(/^UCH-(?<acct_num>\d{0,7})/)
      is_kfs = account_number.match(/^KFS-(?<acct_num>\d{0,7})-(?<obj_code>\d{4})$/)
      if is_uch
        return @@UCH_GLOBAL_DEBIT_ACCOUNT
      elsif is_kfs
        return account_number
      else
        raise "unknown account type: #{account_number}"
      end
    end

    def create_collector_row_string_helper(is_credit)
      account_number = if is_credit then @credit_account_number else @debit_account_number end
      debit_credit_code = if is_credit then "C" else "D" end
      object_code = if is_credit then @credit_object_code else @debit_object_code end

      # Comments indicate the corresponding fields specified in the
      # "General Ledger (GL) Credit Entry" and "General Ledger (GL) Debit Entry" sections
      # of the "Collector Batch Format" document
      entry = [
        # "Fiscal Year" - Changes on July 1st
        @fiscal_year.ljust(4),
        # "Chart of Accounts code"
        @chart_accounts_code.ljust(2),
        # "Account Number" - Account number to be credited or debited
        account_number.ljust(7),
        # "Filler" - Blanks or spaces
        " " * 5,
        # "Object Code" - Object Code to be credited or debited
        object_code.ljust(4),
        # "Filler" - Blanks or spaces
        " " * 3,
        # "Balance Type"
        @bal_record_type.ljust(2),
        # "Filler" - Blanks or spaces
        " " * 4,
        # "Document Type"
        @doc_type.ljust(4),
        # "Origin Code"
        @orig_code.ljust(2),
        # "Document Number – 1st position"
        @doc_from_char.ljust(1),
        # "Document Number – 2 thru 14"
        # An increasing sequential number beginning with zero.
        # Should be the same for each Debit(D) and Credit(C) entry.
        @document_number.to_s.rjust(13, "0"),
        # "Filler" - Blanks or spaces
        " " * 5,
        # "Description" - Transaction Description
        @description.ljust(40),
        # "Filler" - Blanks or spaces
        " " * 1,
        # "Transaction Dollar Amount"
        # Amount to be credited or debited, must include decimal point, for example 00000000000000114.00
        @transaction_dollar_amount.rjust(20, "0"),
        # "Debit/Credit code"
        # "C" for Credit, "D" for Debit
        debit_credit_code.ljust(1),
        # "Transaction Date" - Format CCYY-MM-DD
        @transaction_date.ljust(10),
        # "Organization Document Number"
        # "Usually FRS Reference 1 fields, as long as amount is not to be encumbered."
        @ref_field_1.ljust(10),
        # "Filler" - Blanks or spaces
        " " * 10,
        # "Organization Reference ID"
        # "Usually FRS Reference 2 fields, as long as amount is not to be encumbered."
        @ref_field_2.ljust(8),
        # "Filler" - Blanks or spaces
        " " * 31,
      ]

      return entry.join("")
    end
    
  end
end