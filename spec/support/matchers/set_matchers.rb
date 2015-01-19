RSpec::Matchers.define :contain_all do |expected|
  match do |actual|
    (actual - expected).empty? && (expected - actual).empty?
  end
end

# TODO Use "include(a_string_matching(/pattern/))" instead after upgrading rspec to 3.x
RSpec::Matchers.define :include_a_string_matching do |expected|
  match do |actual|
    actual.any? { |element| element.match(expected) }
  end
end
