#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppConverter

  def convertible_policies
    PricePolicy.where(type: InstrumentPricePolicy.name) # not using #all because we want a relation
  end

  def convertible_details
    OrderDetail.joins(:reservation)
               .where("price_policy_id IS NOT NULL")
               .where(state: %w(new inprocess complete))
  end

  def error_to_log(e, obj)
    "#{obj.class.name} #{obj.id} :: #{e.message}\n#{e.backtrace.keep_if { |t| t =~ /\/nucore-/ }.join("\n")}"
  end

  def new_policy_from(detail)
    InstrumentPricePolicy.new new_policy_attributes_from(detail.price_policy)
  end

  def new_policy_attributes_from(old_policy)
    attrs = old_policy.attributes

    raise "#{old_policy.id} | NO PRODUCT: product_id: #{old_policy.product_id}" unless old_policy.product

    if !old_policy.can_purchase? && old_policy.usage_rate.nil? && old_policy.reservation_rate.nil? && old_policy.overage_rate.nil?
      attrs["charge_for"] = InstrumentPricePolicy::CHARGE_FOR[:reservation]
    elsif old_policy.product.reservation_only? && old_policy.reservation_rate && old_policy.reservation_mins
      if old_policy.usage_rate.to_f > 0 || old_policy.overage_rate.to_f > 0
        puts error_message(old_policy, "Usage and overage are being dropped, and will set to charge for reservation")
        old_policy.usage_rate = nil
        old_policy.overage_rate = nil
      end
      attrs.merge!(
        "usage_rate" => old_policy.reservation_rate * (60 / old_policy.reservation_mins),
        "usage_subsidy" => old_policy.reservation_subsidy * (60 / old_policy.reservation_mins),
        "charge_for" => InstrumentPricePolicy::CHARGE_FOR[:reservation],
      )
    elsif !old_policy.product.reservation_only? && old_policy.usage_rate && old_policy.usage_mins
      attrs.merge!(
        "usage_rate" => old_policy.usage_rate * (60 / old_policy.usage_mins),
        "usage_subsidy" => old_policy.usage_subsidy * (60 / old_policy.usage_mins),
        "charge_for" => InstrumentPricePolicy::CHARGE_FOR[:usage],
      )
    elsif !old_policy.product.reservation_only? && old_policy.reservation_rate && old_policy.overage_rate
      attrs.merge!(
        "usage_rate" => old_policy.reservation_rate * (60 / old_policy.reservation_mins),
        "usage_subsidy" => old_policy.reservation_subsidy * (60 / old_policy.reservation_mins),
        "charge_for" => InstrumentPricePolicy::CHARGE_FOR[:overage],
      )
    else
      error! old_policy, "INVALID CONFIGURATION"
    end

    attrs[:charge_for] = InstrumentPricePolicy::CHARGE_FOR[:overage] if old_policy.overage_rate

    attrs.merge(
      "reservation_rate" => nil,
      "reservation_subsidy" => nil,
      "overage_rate" => nil,
      "overage_subsidy" => nil,
      "reservation_mins" => nil,
      "overage_mins" => nil,
      "usage_mins" => nil,
    )
  end

  def error_message(old_policy, message = "")
    path = "/facilities/#{old_policy.product.facility.url_name}/instruments/#{old_policy.product.url_name}/price_policies"
    status = old_policy.expired? ? "EXPIRED" : "ACTIVE"
    mechanism = old_policy.product.control_mechanism || "reservation"

    rows = [old_policy.id, mechanism, old_policy.reservation_rate.to_f, old_policy.usage_rate.to_f, old_policy.overage_rate.to_f, path, status, message]
    rows.join(" | ")
  end

  def error!(old_policy, message = "")
    raise error_message(old_policy, message)
  end

end
