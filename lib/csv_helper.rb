require 'csv'
module CSVHelper
  def self.generate(&block)
    if defined? FasterCSV
      FasterCSV.generate { |csv| block.call(csv) }
    else
      CSV.generate { |csv| block.call(csv) }
    end
  end
end