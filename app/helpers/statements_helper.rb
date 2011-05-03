module StatementsHelper

  def unreconciled_total(facility)
    unreconciled_total=0

    OrderDetail.unreconciled(facility).each do |od|
      total=od.cost_estimated? ? od.estimated_total : od.actual_total
      unreconciled_total += total if total
    end

    unreconciled_total
  end

end