module NucoreKfs

  class CollectorTransaction

    def initialize(fiscal_year,
                   debit_account_number,
                   credit_account_number,
                   debit_object_code,
                   credit_object_code,
                   document_number,
                   description,
                   transaction_dollar_amount,
                   transaction_date,
                   ref_field_1,
                   ref_field_2
                  )
      @fiscal_year = fiscal_year
      @debit_account_number = debit_account_number
      @credit_account_number = credit_account_number
      @debit_object_code = debit_object_code
      @credit_object_code = credit_object_code
      @document_number = document_number
      @description = description
      @transaction_dollar_amount = transaction_dollar_amount
      @transaction_date = transaction_date
      @ref_field_1 = ref_field_1
      @ref_field_2 = ref_field_2

      # these are always the same. maybe they should be class properties?
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