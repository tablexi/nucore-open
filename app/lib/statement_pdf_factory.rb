# frozen_string_literal: true

class StatementPdfFactory

  @@statement_pdf_class = Settings.statement_pdf.class_name.constantize

  def self.instance(args, **kwargs)
    @@statement_pdf_class.new(args, **kwargs)
  end

end
