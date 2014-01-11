require 'csv'

#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppCsvBuilder

  attr_reader :csv


  def initialize
    @csv = CSV.open 'price_change_report.csv', 'w'

    csv << [
      'facility',
      'instrument',
      'order id',
      'minutes reserved',
      'minutes used',
      'old cost estimate',
      'new cost estimate',
      'old subsidy estimate',
      'new subsidy estimate',
      'old cost actual',
      'new cost actual',
      'old subsidy actual',
      'new subsidy actual'
    ]
  end


  def report(detail, actuals, estimates)
    reservation = detail.reservation
    product = detail.product

    csv << [
      product.facility.name,
      product.name,
      detail.to_s,
      ((reservation.reserve_end_at - reservation.reserve_start_at) / 60).to_i,
      ((reservation.actual_end_at - reservation.actual_start_at) / 60).to_i,
      detail.estimated_cost.to_f,
      estimates[:cost].to_f,
      detail.estimated_subsidy.to_f,
      estimates[:subsidy].to_f,
      detail.actual_cost.to_f,
      actuals[:cost].to_f,
      detail.actual_subsidy.to_f,
      actuals[:subsidy].to_f
    ]
  end


  def render
    csv.close
  end

end
