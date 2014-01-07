#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class InstrumentPricePolicyComparator

  attr_reader :details
  attr_accessor :changed


  def initialize
    @changed = 0
    @details = OrderDetail.joins(:reservation)
                          .where('price_policy_id IS NOT NULL')
                          .where(state: [ 'New', 'In Process', 'Complete' ])
  end


  def report_changes
    details.find_each do |detail|
      begin
        new_price_policy = new_policy_from detail
        actuals = new_price_policy.calculate_cost_and_subsidy_from_order_detail detail
        estimates = new_price_policy.estimate_cost_and_subsidy_from_order_detail detail

        unless same? detail, actuals, estimates
          self.changed += 1
          report detail, actuals, estimates
        end
      rescue => e
        puts "#{detail.to_s} :: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end

    summarize
  end


  def new_policy_from(detail)
    old_policy = detail.price_policy
    attrs = old_policy.attributes

    if detail.product.reservation_only? && old_policy.reservation_rate && old_policy.reservation_mins
      attrs.merge!(
        'usage_rate' => old_policy.reservation_rate * (60 / old_policy.reservation_mins),
        'charge_for' => InstrumentPricePolicy::CHARGE_FOR[:reservation]
      )
    elsif old_policy.usage_rate && old_policy.usage_mins
      attrs.merge!(
        'usage_rate' => old_policy.usage_rate * (60 / old_policy.usage_mins),
        'charge_for' => InstrumentPricePolicy::CHARGE_FOR[:usage]
      )
    else
      raise "Cannot determine calculation type of policy #{old_policy.id}!"
    end

    attrs.merge! charge_for: InstrumentPricePolicy::CHARGE_FOR[:overage] if old_policy.overage_rate

    attrs.merge!(
      'reservation_rate' => nil,
      'reservation_subsidy' => nil,
      'overage_rate' => nil,
      'overage_subsidy' => nil,
      'reservation_mins' => nil,
      'overage_mins' => nil,
      'usage_mins' => nil
    )

    InstrumentPricePolicy.new attrs
  end


  def same?(detail, actuals, estimates)
    detail.estimated_cost == estimates[:cost] &&
    detail.estimated_subsidy == estimates[:subsidy] &&
    detail.actual_cost == actuals[:cost] &&
    detail.actual_subsidy == actuals[:subsidy]
  end


  def report(detail, actuals, estimates)
    reservation = detail.reservation

    puts <<-REPORT
      [ EST. MINS  ] #{(reservation.reserve_end_at - reservation.reserve_start_at) / 60}
      [ EST. COST  ] old: #{detail.estimated_cost.to_f}     new: #{estimates[:cost].to_f}
      [ EST. SUB   ] old: #{detail.estimated_subsidy.to_f}  new: #{estimates[:subsidy].to_f}
      [ ACT. MINS  ] #{(reservation.actual_end_at - reservation.actual_start_at) / 60}
      [ ACT. COST  ] old: #{detail.actual_cost.to_f}        new: #{actuals[:cost].to_f}
      [ ACT. SUB   ] old: #{detail.actual_subsidy.to_f}     new: #{actuals[:subsidy].to_f}

    REPORT
  end


  def summarize
    puts "#{details.size} new, in process, or completed reservations processed"
    puts "#{changed} had different prices while #{details.size - changed} were the same"
  end

end
