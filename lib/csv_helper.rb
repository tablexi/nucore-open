module CSVHelper
  def self.get_csv
    case RUBY_VERSION
    when "1.8.7"
      unless defined?(FasterCSV)
        require 'faster_csv'
      end

      return FasterCSV
    else
      unless defined?(CSV)
        require 'csv'
      end

      return CSV
    end
  end

  def self.generate(&block)
    self.get_csv.generate { |csv| block.call(csv) }
  end

  def self.parse(file_path, &block)
    self.get_csv.parse(file_path, :headers => true, &block)
  end

  def set_csv_headers(filename)
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain"
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = "0"
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
    end
  end
end
