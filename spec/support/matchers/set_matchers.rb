RSpec::Matchers.define :contain_all do |expected|
  match do |actual|
    (actual - expected).empty?
  end
end