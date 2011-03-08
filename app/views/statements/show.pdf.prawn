pdf.font_size = 10.5

pdf.text @facility.to_s, :size => 20, :style => :bold
pdf.text "Invoice ##{@account.id}-#{@statement.id}"

if @facility.has_contact_info?
  pdf.text @facility.address if @facility.address
  pdf.move_down(10)
  pdf.text "<b>Phone Number:</b> #{@facility.phone_number}", :inline_format => true if @facility.phone_number
  pdf.text "<b>Fax Number:</b> #{@facility.fax_number}", :inline_format => true if @facility.fax_number
  pdf.text "<b>Email:</b> #{@facility.email}", :inline_format => true if @facility.email
end

if @account.remittance_information
  pdf.move_down(10)
  pdf.text "Bill To:", :style => :bold
  pdf.text @account.remittance_information
end

rows = @account_txns.map do |at|
  [
    human_datetime(at.created_at),
    at.type_string,
    (at.is_a?(PaymentAccountTransaction) ? 'Payment received.  Thank you.' : at.description),
    number_to_currency(at.transaction_amount)
  ]
end
headers = ["Transaction Date", "Transaction Type", "Description", "Amount"]

pdf.move_down(30)
pdf.table([headers] + rows, :header => true, :width => 510) do
  row(0).style(:style => :bold, :background_color => 'cccccc')
  column(0).width = 125
  column(1).width = 105
  column(3).width = 70
  column(3).style(:align => :right)
end

rows = [ ['<b>Previous Balance</b>',     number_to_currency(@balance_prev) ],
         ['<b>New Payments/Credits</b>', number_to_currency(@new_payments) ],
         ['<b>New Purchases</b>',        number_to_currency(@new_purchases)],
         ['<b>Balance Due</b>',          number_to_currency(@balance_due)  ] ]

pdf.table(rows, :width => 510, :cell_style => { :borders => [] }) do
  column(1).width = 70
  column(0).style(:align => :right, :inline_format => true)
  column(1).style(:align => :right)
end

pdf.number_pages "Page <page> of <total>", [0, -15]
