RSpec::Matchers.define :match_date do |expected|
  match do |actual|
    (actual - expected).abs <= 1.0
  end
end

RSpec::Matchers.define :include_date do |expected|
  match do |actual|
  	actual.any? { |a| (a - expected).abs <= 1.0 }
  end
end