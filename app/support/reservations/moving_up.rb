# Support for finding the next available time and moving a reservation
# up to that next time slot
module Reservations::MovingUp
  #
  # Returns a clone of this reservation with the reserve_*_at times updated
  # to the next accommodating time slot on the calendar from NOW. Returns nil
  # if there is no such time slot. The clone is frozen so don't try to change
  # it. It's for read-only purposes.
  def earliest_possible
    clone=self.clone
    after=Time.zone.now+1.minute

    while true
      next_res=product.next_available_reservation(after, self)

      return nil if next_res.nil? or next_res.reserve_start_at > reserve_start_at

      clone.reserve_start_at=next_res.reserve_start_at
      clone.reserve_end_at=next_res.reserve_start_at.advance(:minutes => duration_mins)

      if instrument_is_available_to_reserve? && does_not_conflict_with_other_reservation?
        clone.freeze
        return clone
      end

      after=next_res.reserve_end_at
    end
  end

  def move_to_earliest
    earliest_found = earliest_possible
    if earliest_found
      self.reserve_start_at = earliest_found.reserve_start_at
      self.reserve_end_at = earliest_found.reserve_end_at
      if save
        return true
      else
        self.errors.add(:base, :move_failed)
      end
    else
      self.errors.add(:base, :cannot_move)
    end
    false
  end

  #
  # returns true if this reservation can be moved to
  # an earlier time slot, false otherwise
  def can_move?
    !(cancelled? || order_detail.complete? || earliest_possible.nil?)
  end
end