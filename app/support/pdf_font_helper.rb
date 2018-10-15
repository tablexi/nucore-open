# frozen_string_literal: true

class PdfFontHelper

  class << self

    delegate :set_fonts, to: :new

  end

  def set_fonts(pdf)
    return if font_name.blank?

    pdf.font_families.update(font_name => file_mappings)
    pdf.font(font_name)
  end

  private

  def font_name
    Settings.statement_pdf.font_name
  end

  def mappings
    {
      normal: "Regular",
      italic: "Italic",
      bold: "Bold",
    }
  end

  def file_mappings
    mappings.each_with_object({}) do |(k, v), hash|
      hash[k] = Rails.root.join("app/assets/fonts/#{font_name}-#{v}.ttf") if v.present?
    end
  end

end
