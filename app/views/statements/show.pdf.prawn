prawn_document @statement_pdf.options do |pdf|
  PdfFontHelper.set_fonts(pdf)
  @statement_pdf.generate(pdf)
end
