$ ->
  if isBundle? && !isBundle && !ordering_on_behalf
    # Event triggered by ReservationTimeFieldAdjustor
    $(".js--reservationUpdateCreateAndStart").on "reservation:times_changed", (evt, reservation_time_data) ->

      return if ctrlMechanism == "manual"
      return unless instrumentOnline

      now = new Date()
      grace_time = now.clone().addMinutes(5)
      picked = reservation_time_data.start

      # change reservation creation button based on Reservation
      text = if picked.between(now, grace_time) then "Create & Start" else "Create"
      $("#reservation_submit").attr("value", text)
