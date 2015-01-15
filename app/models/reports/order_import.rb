class Reports::OrderImport
  def initialize(order_import)
    @order_import = order_import
  end

  def description
    "Bulk Order Import Results"
  end

  def text_content
    "The results of your bulk order upload were:\n"\
    "  Sucessful imports: #{@order_import.result.successes}\n"\
    "  Failed imports: #{@order_import.result.failures}\n"
  end

  def to_csv
    @order_import.error_file_content
  end
end
