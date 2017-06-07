RSpec::Matchers.define :have_column do |column_header|
  match do |report|
    headers = report.column_headers
    @column_index = headers.index(column_header)
    lines = report.to_csv.split("\n").drop(1)
    break false unless @column_index
    @actual_values = lines.map { |line| line.split(",")[@column_index].to_s }
    @actual_values == @expected_values
  end

  chain :with_value do |value|
    @expected_values = Array(value)
  end

  chain :with_values do |*values|
    @expected_values = Array(values).flatten
  end

  failure_message do
    if @actual_values
      %(Expected report to have value(s) "#{@expected_values.join(', ')}" in column #{column_header}, but got "#{@actual_values.join(', ')}")
    else
      %(Report did not have column with header "#{column_header}")
    end
  end
end
