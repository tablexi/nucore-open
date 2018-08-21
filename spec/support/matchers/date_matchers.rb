# frozen_string_literal: true

# I used to have the margin of error set to 1.0, but that would fail occassionally with slightly more than that
# like 1.16 or so.
RSpec::Matchers.define :match_date do |expected|
  match do |actual|
    (actual - expected).abs <= 2.0
  end
end

RSpec::Matchers.define :include_date do |expected|
  match do |actual|
    actual.any? { |a| (a - expected).abs <= 2.0 }
  end
end
