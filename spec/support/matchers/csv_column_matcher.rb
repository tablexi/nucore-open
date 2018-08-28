# frozen_string_literal: true

require "csv"
require "pry"
# Examples:
# expect(report).to have_column("Quantity")
# expect(report).to have_column("Quantity").with_value("1")
# expect(report).to have_column("Quantity").with_value(a_string_starting_with("1"))
# expect(report).to have_column("Quantity").with_value(/1/)
# expect(report).to have_column("Quantity").with_values("1", "2")
# expect(report).to have_column("Quantity").with_values(["1", "2"])
RSpec::Matchers.define :have_column do |column_header|
  match do |report|
    csv = CSV.parse(report.to_csv, headers: true)
    break false unless csv.headers.include?(column_header)
    break true unless @expected_values

    @actual_values = csv.map { |row| row[column_header].to_s }
    break false if @actual_values.length != @expected_values.length

    # Compare each pair. Case equality allows using regexes and rspecs
    # composable matchers.
    @expected_values.zip(@actual_values).all? do |expected, actual|
      expected === actual # rubocop:disable Style/CaseEquality
    end
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

# Examples:
# expect(report).to have_column_values(
#   "Quantity" => "0.5",
#   "Actual Cost" => "$10.00",
# )
# expect(report).to have_column_values(
#   "Quantity" => ["0.5", "0.5"],
#   "Actual Cost" => ["$10.00", "$9.99"],
# )
#
RSpec::Matchers.define :have_column_values do |column_values_hash|
  match do |report|
    @failures = column_values_hash.each_with_object([]) do |(column_header, values), memo|
      matcher = have_column(column_header).with_values(values)
      memo << matcher.failure_message unless matcher.matches?(report)
    end
    @failures.empty?
  end

  failure_message do
    @failures.join("\n")
  end
end
