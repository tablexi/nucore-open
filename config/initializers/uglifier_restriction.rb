# frozen_string_literal: true

unless Uglifier::VERSION == "4.1.18"
  raise "Uglifier 4.1.19 has a bug (https://github.com/mishoo/UglifyJS2/issues/3245).
  Please ensure it's fixed before advancing"
end
