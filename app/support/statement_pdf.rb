# frozen_string_literal: true

class StatementPdf

  include ActionView::Helpers::NumberHelper
  include DateHelper

  LABEL_ROW_STYLE = { font_style: :bold, background_color: "cccccc" }.freeze

  DEFAULT_OPTIONS = {
    left_margin: 50,
    right_margin: 50,
    top_margin: 50,
    bottom_margin: 75,
  }.freeze

  def options
    if download?
      DEFAULT_OPTIONS.merge(filename: filename, force_download: true)
    else
      DEFAULT_OPTIONS.dup
    end
  end

  def initialize(statement, download: false)
    @statement = statement
    @account = statement.account
    @facility = statement.facility
    @download = download
  end

  def download?
    @download
  end

  def filename
    date = I18n.l(@statement.created_at.to_date, format: :usa_filename_safe)
    I18n.t("statements.pdf.filename", date: date,
                                      facility: @facility.abbreviation.gsub(/\s+/, "_"),
                                      invoice_number: @statement.invoice_number)
  end

  def render
    pdf = Prawn::Document.new(options)
    generate(pdf)
    pdf.render
  end

  def generate(pdf)
    generate_document_header(pdf)
    generate_contact_info(pdf) if @facility.has_contact_info?
    generate_remittance_information(pdf) if @account.remittance_information.present?
    generate_order_detail_rows(pdf)
    generate_document_footer(pdf)
  end

  private

  def generate_contact_info(pdf)
    pdf.text @facility.address if @facility.address
    pdf.move_down(10)

    %w(phone_number fax_number email).each do |contact_field|
      field_value = @facility.send(contact_field.to_sym)
      next if field_value.blank?
      pdf.text "<b>#{contact_field.titleize}:</b> #{field_value}", inline_format: true
    end
  end

  def generate_document_footer(pdf)
    pdf.number_pages "Page <page> of <total>", at: [0, -15]
  end

  def generate_document_header(pdf)
    pdf.font_size = 10.5

    pdf.text @facility.to_s, size: 20, font_style: :bold
    pdf.text "Invoice ##{@statement.invoice_number}"
    pdf.text "Account: #{@account}"
    pdf.text "Owner: #{@account.owner.user.full_name(suspended_label: false)}"
    pdf.move_down(10)
  end

  def generate_order_detail_rows(pdf)
    pdf.move_down(30)
    pdf.table([order_detail_headers] + order_detail_rows, header: true, width: 510) do
      row(0).style(LABEL_ROW_STYLE)
      column(0).width = 125
      column(1).width = 225
      column(2).width = 75
      column(2).style(align: :right)
      column(3).style(align: :right)
    end
  end

  def generate_remittance_information(pdf)
    pdf.move_down(10)
    pdf.text "Bill To:", font_style: :bold
    pdf.text @account.remittance_information
  end

  def order_detail_headers
    ["Fulfillment Date", "Order", "Quantity", "Amount"]
  end

  def order_detail_rows
    @statement.order_details.includes(:product).order("fulfilled_at DESC").map do |order_detail|
      [
        format_usa_datetime(order_detail.fulfilled_at),
        "##{order_detail}: #{order_detail.product}" + (order_detail.note.blank? ? "" : "\n#{order_detail.note}"),
        OrderDetailPresenter.new(order_detail).wrapped_quantity,
        number_to_currency(order_detail.actual_total),
      ]
    end
  end

end
