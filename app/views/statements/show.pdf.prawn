pdf_config={
  :left_margin   => 50,
  :right_margin  => 50,
  :top_margin    => 50,
  :bottom_margin => 75
}

prawn_document pdf_config do |pdf|

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

  rows = @statement.order_details.sort{|d,o| d.order.ordered_at<=>o.order.ordered_at}.reverse.map do |od|
    [
      human_datetime(od.order.ordered_at),
      "##{od}: #{od.product}" + (od.note.blank? ? '' : "\n#{od.note}"),
      number_to_currency(od.actual_total)
    ]
  end
  headers = ["Transaction Date", "Order", "Amount"]

  pdf.move_down(30)
  pdf.table([headers] + rows, :header => true, :width => 510) do
    row(0).style(:style => :bold, :background_color => 'cccccc')
    column(0).width = 125
    column(1).width = 300
    column(2).style(:align => :right)
  end

  pdf.number_pages "Page <page> of <total>", [0, -15]

end