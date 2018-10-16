# frozen_string_literal: true

class ReconcilliationsController < ApplicationController

  load_resource :order
  load_resource :order_detail, through: :order

  def destroy
    if current_user.administrator?
      @order_detail.update!(state: "complete", order_status: OrderStatus.complete, reconciled_at: nil)
      redirect_to facility_transactions_path(current_facility)
    else
      raise CanCan::AccessDenied
    end
  end

end
