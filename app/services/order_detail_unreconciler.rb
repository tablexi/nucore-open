# frozen_string_literal: true

# Currently only used from the console or in a rake task
class OrderDetailUnreconciler

  def initialize(order_details)
    @order_details = order_details
  end

  def perform
    perform!(true)
  end

  def perform!(dry_run = false)
    OrderDetail.transaction do
      @order_details.find_each do |od|
        Rails.logger.info "Unreconciling Order #{od}"
        od.update(state: "complete", order_status: complete_status, reconciled_at: nil)
      end
      raise ActiveRecord::Rollback if dry_run
    end
    @order_details
  end

  private

  def complete_status
    OrderStatus.complete_status
  end

end
