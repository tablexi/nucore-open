# frozen_string_literal: true

RSpec::Matchers.define :appear_before do |later_content|
  match do |earlier_content|
    page.body.index(earlier_content) < page.body.index(later_content)
  end
end

RSpec::Matchers.define :appear_in_order do
  match do |expected_order|
    actual_order = actual_order_for(expected_order)
    actual_order == expected_order
  end

  failure_message do |expected_order|
    actual_order = actual_order_for(expected_order)
    "expected #{expected_order}, but actual order was #{actual_order}"
  end

  def actual_order_for(expected_content)
    actual_order = expected_content.map do |content|
      next if page.body.index(content).nil?

      [content, page.body.index(content)]
    end
    actual_order.compact.sort_by(&:last).map(&:first)
  end
end
