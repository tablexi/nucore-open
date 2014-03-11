require 'csv'

#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppMigrationReporter

  def report_price_policies(pp_ids)
    headers = %w(facility instrument)
    policies = InstrumentPricePolicy.includes(product: :facility).where id: pp_ids

    create_csv 'price_policies', headers do |csv|
      policies.each {|pp| csv << price_policy_row(pp) }
    end
  end


  def report_order_details(od_ids)
    headers = %w(id facility instrument state policy_mode reserve_start reserve_end actual_start actual_end)
    details = OrderDetail.includes(product: :facility).includes(:price_policy, :reservation).where id: od_ids

    create_csv 'order_details', headers do |csv|
      details.each {|od| csv << order_detail_row(od) }
    end
  end


  def report_journaled_details(oids_to_attrs)
    headers = %w(id facility instrument actual_cost actual_subsidy estimated_cost estimated_subsidy
                 old_actual_cost old_actual_subsidy old_estimated_cost old_estimated_subsidy journaled_amount)

    details = OrderDetail.find oids_to_attrs.keys

    create_csv 'journaled_details', headers do |csv|
      details.each {|od| csv << journal_detail_row(od, oids_to_attrs[od.id]) }
    end
  end


  private

  def create_csv(filename, headers)
    csv = CSV.open "#{filename}.csv", 'w'
    csv << headers
    yield csv
    csv.close
  end


  def price_policy_row(pp)
    product = pp.product
    [ product.facility.name, product.name ]
  end


  def order_detail_row(od)
    product = od.product
    reservation = od.reservation

    [
      od.to_s,
      product.facility.name,
      product.name,
      od.state,
      od.price_policy.charge_for,
      reservation.reserve_start_at,
      reservation.reserve_end_at,
      reservation.actual_start_at,
      reservation.actual_end_at
    ]
  end


  def journal_detail_row(od, old_attrs)
    product = od.product

    [
      od.to_s,
      product.facility.name,
      product.name,
      od.actual_cost,
      od.actual_subsidy,
      od.estimated_cost,
      od.estimated_subsidy,
      old_attrs['actual_cost'],
      old_attrs['actual_subsidy'],
      old_attrs['estimated_cost'],
      old_attrs['estimated_subsidy'],
      od.journal.journal_rows.where(order_detail_id: od.id).first.amount
    ]
  end

end
