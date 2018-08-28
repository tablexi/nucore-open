# frozen_string_literal: true

RSpec::Matchers.define :contain_all do |expected|
  match do |actual|
    (actual - expected).empty? && (expected - actual).empty?
  end
end
