class OrderDetailBatchUpdater

  # TODO: Extracted from the OrderDetail model almost as-is and still needs refactoring

  attr_accessor :facility, :msg_hash, :msg_type, :order_detail_ids, :user, :params

  # returns a hash of :notice (and/or?) :error
  # these should be shown to the user as an appropriate flash message
  #
  # Required Parameters:
  #
  # order_detail_ids: enumerable of strings or integers representing
  #                   order_details to attempt update of
  #
  # params:           a hash containing updates to attempt on the order_details
  #
  # user:             user requesting the update
  #
  # Acceptable Updates:
  #   key                     value
  #   ---------------------------------------------------------------------
  #   :assigned_user_id       integer or string: id of a User
  #                                              they should be assigned to
  #
  #                                               OR
  #
  #                                              'unassign'
  #                                              (to unassign current user)
  #
  #
  #   :order_status_id        integer or string: id of an OrderStatus
  #                                              they should be set to
  #
  #
  # Optional Parameters:
  #
  # msg_type:         a plural string used in error/success messages to indicate
  #                   type of records,
  #                   (since this class method is also used to update
  #                   order_details associated with reservations)
  #                   defaults to 'orders'

  def self.permitted_attributes
    @permitted_attributes ||= %i(assigned_user_id order_status_id)
  end

  def initialize(order_detail_ids, facility, user, params, msg_type = "orders")
    @order_detail_ids = order_detail_ids
    @facility = facility
    @user = user
    @params = params
    @msg_type = msg_type
    @msg_hash = {}
  end

  def update!
    @changes = false

    unless order_detail_ids.present?
      msg_hash[:error] = "No #{msg_type} selected"
      return msg_hash
    end

    if order_details.any? { |od| !(od.state.include?("inprocess") || od.state.include?("new")) }
      msg_hash[:error] = "There was an error updating the selected #{msg_type}"
      return msg_hash
    end

    OrderDetail.transaction do
      update_order_details_from_params

      if params[:order_status_id].present?
        @changes = true
        begin
          os = OrderStatus.find(params[:order_status_id])
          order_details.each do |od|
            # cancel reservation order details
            if os.id == OrderStatus.canceled.first.id && od.reservation
              raise "#{msg_type} ##{od} failed cancellation." unless od.cancel_reservation(user, os, true)
            # cancel other orders or change status of any order
            else
              od.change_status!(os)
            end
          end
        rescue => e
          msg_hash[:error] = "There was an error updating the selected #{msg_type}.  #{e.message}"
          raise ActiveRecord::Rollback
        end
      end

      unless @changes
        msg_hash[:notice] = "No changes were required"
        return msg_hash
      end

      begin
        order_details.all?(&:save!)
        msg_hash[:notice] = "The #{msg_type} were successfully updated"
      rescue
        msg_hash[:error] = "There was an error updating the selected #{msg_type}"
        raise ActiveRecord::Rollback
      end
    end

    msg_hash
  end

  private

  def order_details
   @order_details ||= facility.order_details.where(id: order_detail_ids)
  end

  def update_order_details_from_params
    self.class.permitted_attributes.each do |attribute|
      next if attribute == :order_status_id # Special case
      next if params[attribute].blank?

      @changes = true

      value = params[attribute] == "unassign" ? nil : params[attribute]

      order_details.each do |order_detail|
        order_detail.public_send("#{attribute}=", value)
      end
    end
  end

end
