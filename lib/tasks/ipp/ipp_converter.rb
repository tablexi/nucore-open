#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppConverter

  def convertible_policies
    PricePolicy.where(type: InstrumentPricePolicy.name) # not using #all because we want a relation
  end


  def convertible_details
    OrderDetail.joins(:reservation)
               .where('price_policy_id IS NOT NULL')
               .where(state: %w(new inprocess complete))
  end


  def error_to_log(e, obj)
    "#{obj.class.name} #{obj.id} :: #{e.message}\n#{e.backtrace.keep_if{|t| t =~ /\/nucore-/ }.join("\n")}"
  end


  def new_policy_from(detail)
    convert_policy detail.price_policy
  end


  def convert_policy(old_policy)
    attrs = old_policy.attributes

    if old_policy.product.reservation_only? && old_policy.reservation_rate && old_policy.reservation_mins
      attrs.merge!(
        'usage_rate' => old_policy.reservation_rate * (60 / old_policy.reservation_mins),
        'usage_subsidy' => old_policy.reservation_subsidy * (60 / old_policy.reservation_mins),
        'charge_for' => InstrumentPricePolicy::CHARGE_FOR[:reservation]
      )
    elsif old_policy.usage_rate && old_policy.usage_mins
      attrs.merge!(
        'usage_rate' => old_policy.usage_rate * (60 / old_policy.usage_mins),
        'usage_subsidy' => old_policy.usage_subsidy * (60 / old_policy.usage_mins),
        'charge_for' => InstrumentPricePolicy::CHARGE_FOR[:usage]
      )
    else
      raise "Cannot determine calculation type of policy #{old_policy.id}!"
    end

    attrs.merge! charge_for: InstrumentPricePolicy::CHARGE_FOR[:overage] if old_policy.overage_rate

    InstrumentPricePolicy.new attrs.merge(
      'reservation_rate' => nil,
      'reservation_subsidy' => nil,
      'overage_rate' => nil,
      'overage_subsidy' => nil,
      'reservation_mins' => nil,
      'overage_mins' => nil,
      'usage_mins' => nil
    )
  end

end
