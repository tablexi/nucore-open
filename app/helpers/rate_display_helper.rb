# frozen_string_literal: true

module RateDisplayHelper

  def hidden_price_policy_tag(price_group_id, cost, cost_field, policy_param)
    hidden_field_tag "price_policy_#{price_group_id}[#{cost_field}]",
                     policy_param ? policy_param[cost_field] : number_to_currency(cost, unit: "", delimiter: ""),
                     size: 8, class: cost_field
  end

end
