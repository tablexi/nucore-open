module Reservations::Validations
  extend ActiveSupport::Concern

  included do
    validates_uniqueness_of :order_detail_id, :allow_nil => true
    validates_presence_of :product_id, :reserve_start_at, :reserve_end_at
    validate :does_not_conflict_with_other_reservation,
             :instrument_is_available_to_reserve,
             :satisfies_minimum_length,
             :satisfies_maximum_length,
             :if => :reserve_start_at && :reserve_end_at && :reservation_changed?,
             :unless => :admin?

    validates_each [ :actual_start_at, :actual_end_at ] do |record,attr,value|
      if value
        record.errors.add(attr.to_s,'cannot be in the future') if Time.zone.now < value
      end
    end

    validate :starts_before_ends
  end

  # Validation Methods

  def starts_before_ends
    if reserve_start_at && reserve_end_at
      errors.add('reserve_end_date','must be after the reservation start time') if reserve_end_at <= reserve_start_at
    end
    if actual_start_at && actual_end_at
      errors.add('actual_end_date','must be after the actual start time') if actual_end_at <= actual_start_at
    end
  end

  def does_not_conflict_with_other_reservation?
    conflicting_reservation.nil?
  end

  def does_not_conflict_with_other_reservation
    res=conflicting_reservation

    if res
      msg = res.order.try(:==, order) ? :conflict_in_cart : :conflict
      errors.add(:base, msg)
    end
  end

  #
  # Look for a reservation on the same instrument that conflicts in time with a
  # purchased, admin, or in-cart reservation. Should not check reservations that
  # are unpurchased in other user's carts.
  def conflicting_reservation
    order_id = order_detail.try(:order_id) || 0

    conflicting_reservations =
      Reservation.
        joins_order.
        where(:product_id => product.schedule.product_ids).
        not_this_reservation(self).
        not_cancelled.
        not_started.
        where("(orders.state = 'purchased' OR orders.state IS NULL OR orders.id = ?)", order_id).
        overlapping(reserve_start_at, reserve_end_at)

    conflicting_reservations.first
  end

  def satisfies_minimum_length?
    diff = reserve_end_at - reserve_start_at # in seconds
    return false unless product.min_reserve_mins.nil? || product.min_reserve_mins == 0 || diff/60 >= product.min_reserve_mins
    true
  end

  def satisfies_minimum_length
    errors.add(:base, "The reservation is too short") unless satisfies_minimum_length?
  end

  def satisfies_maximum_length?
    diff = reserve_end_at - reserve_start_at # in seconds
    return false unless product.max_reserve_mins.nil? || product.max_reserve_mins == 0 || diff/60 <= product.max_reserve_mins
    true
  end

  def satisfies_maximum_length
    errors.add(:base, "The reservation is too long") unless satisfies_maximum_length?
  end

  def instrument_is_available_to_reserve
    errors.add(:base, "The reservation spans time that the instrument is unavailable for reservation") unless instrument_is_available_to_reserve?
  end

  def instrument_is_available_to_reserve? (start_at = self.reserve_start_at, end_at = self.reserve_end_at)

    # check for order_detail and order because some old specs don't set an order detail
    # if we're saving as an administrator, we want access to all schedule rules
    if (order_detail and order_detail.order and !@reserved_by_admin)
      rules = product.available_schedule_rules(order_detail.order.user)
    else
      rules = product.schedule_rules
    end

    mins  = (end_at - start_at)/60
    (0..mins).each { |n|
      dt    = start_at.advance(:minutes => n)
      found = false
      rules.each { |s|
        if s.includes_datetime(dt)
          found = true
          break
        end
      }
      unless found
        return false
      end
    }
    true
  end

  # Extended validation methods
  def save_extended_validations(options ={})
    perform_validations(options)
    in_window
    in_the_future
    return false if self.errors.any?
    self.save
  end

  def save_extended_validations!
    raise ActiveRecord::RecordInvalid.new(self) unless save_extended_validations()
  end

  def in_the_future?
    reserve_start_at > Time.zone.now
  end

  def in_the_future
    errors.add(:reserve_start_at, "The reservation must start at a future time") unless in_the_future?
  end

  # checks that the reservation is within the longest window for the groups the user is in
  def in_window?
    groups   = order_detail.price_groups
    max_days = longest_reservation_window(groups)
    diff     = reserve_start_at.to_date - Date.today
    diff <= max_days
  end

  def in_window
    errors.add(:base, "The reservation is too far in advance") unless in_window?
  end

  # return the longest available reservation window for the groups
  def longest_reservation_window(groups = [])
    return default_reservation_window if groups.empty?
    pgps     = product.price_group_products.find(:all, :conditions => {:price_group_id => groups.collect{|pg| pg.id}})
    pgps.collect{|pgp| pgp.reservation_window}.max
  end

  private

  def default_reservation_window
    product.price_group_products.map(&:reservation_window).min
  end


end