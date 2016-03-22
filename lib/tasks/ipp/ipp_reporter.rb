require_relative "ipp_converter"
require_relative "ipp_csv_builder"
require_relative "ipp_html_builder"

#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppReporter

  attr_accessor :changed

  attr_reader :details,
              :errors,
              :html_builder,
              :csv_builder,
              :converter

  def initialize
    @changed = 0
    @errors = []
    @converter = IppConverter.new
    @csv_builder = IppCsvBuilder.new
    @html_builder = IppHtmlBuilder.new
    @details = converter.convertible_details
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
        new_price_policy = converter.new_policy_from detail
        actuals = new_price_policy.calculate_cost_and_subsidy_from_order_detail detail
        estimates = new_price_policy.estimate_cost_and_subsidy_from_order_detail detail

        next if same? detail, actuals, estimates

        self.changed += 1
        html_builder.report detail, actuals, estimates
        csv_builder.report detail, actuals, estimates
      rescue => e
        errors << converter.error_to_log(e, detail)
      end
    end
  end

  def same?(detail, actuals, estimates)
    detail.estimated_cost == estimates[:cost] &&
      detail.estimated_subsidy == estimates[:subsidy] &&
      detail.actual_cost == actuals[:cost] &&
      detail.actual_subsidy == actuals[:subsidy]
  end

end
