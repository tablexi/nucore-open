module ProductsHelper
  def price_policy_errors(product)

    @facility_price_groups ||= current_facility.price_groups.count
    price_policy_count = product.price_policies.current.count
    error_msg = ''
    if price_policy_count == 0
      error_msg = t('price_policies.errors.none_exist')
    elsif price_policy_count < @facility_price_groups
      #TODO Add in once products have been updated with the newer can_purchase policies
      # in the transition, its possible that a group who is restricted from purchasing may not have
      # a price policy and we don't want to scare people
      #error_msg = t('price_policies.errors.fewer_than_price_groups')
    end
    error_msg ? "<span class=\"price_policy_error\">#{error_msg}</span>".html_safe : ""
  end

  def options_for_control_mechanism
    Relay::CONTROL_MECHANISMS.inject(ActiveSupport::OrderedHash.new) do |hash, (key, v)|
      human_value = t("instruments.instrument_fields.relay.control_mechanisms.#{key}")
      hash[human_value] = key
      hash
    end
  end

  def options_for_relay
    #TODO Replace with normal hash
    ActiveSupport::OrderedHash[
      RelaySynaccessRevA, RelaySynaccessRevA.name,
      RelaySynaccessRevB, RelaySynaccessRevB.name
    ]
  end
end