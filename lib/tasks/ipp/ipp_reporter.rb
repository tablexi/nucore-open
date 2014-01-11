require_relative 'ipp_csv_builder'
require_relative 'ipp_html_builder'

#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppReporter

  attr_accessor :changed
  attr_reader :details, :errors, :html_builder, :csv_builder


  def initialize
    @changed = 0
    @errors = []
    @csv_builder = IppCsvBuilder.new
    @html_builder = IppHtmlBuilder.new
    @details = OrderDetail.joins(:reservation)
                          .where('price_policy_id IS NOT NULL')
                          .where(state: %w(new inprocess complete))
  end


  def report_changes
    build_report
    html_builder.summarize self
    html_builder.report_errors self
    html_builder.render
    csv_builder.render
  end


  def build_report
    details.find_each do |detail|
      begin
        new_price_policy = new_policy_from detail
        actuals = new_price_policy.calculate_cost_and_subsidy_from_order_detail detail
        estimates = new_price_policy.estimate_cost_and_subsidy_from_order_detail detail

        unless same? detail, actuals, estimates
          self.changed += 1
          html_builder.report detail, actuals, estimates
          csv_builder.report detail, actuals, estimates
        end
      rescue => e
        errors << error_line(e, detail)
      end
    end
  end


  def new_policy_from(detail)
    old_policy = detail.price_policy
    attrs = old_policy.attributes

    if detail.product.reservation_only? && old_policy.reservation_rate && old_policy.reservation_mins
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


  def same?(detail, actuals, estimates)
    detail.estimated_cost == estimates[:cost] &&
    detail.estimated_subsidy == estimates[:subsidy] &&
    detail.actual_cost == actuals[:cost] &&
    detail.actual_subsidy == actuals[:subsidy]
  end


  def error_line(e, detail)
    "#{detail.to_s} :: #{e.message}\n#{e.backtrace.keep_if{|t| t =~ /nucore-/ }.join("\n")}"
  end

end
