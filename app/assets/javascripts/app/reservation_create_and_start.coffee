$ ->
  if isBundle? && !isBundle && !ordering_on_behalf
    # Event triggered by ReservationTimeFieldAdjustor
    $(".js--reservationUpdateCreateAndStart").on "reservation:times_changed", (evt, data) ->

      return if ctrlMechanism == "manual"
      return unless instrumentOnline

      now = new Date()
      future = now.clone().addMinutes(5)
      picked = data.start

      # change reservation creation button based on Reservation
      text = if picked.between(now, future) then "Create & Start" else "Create"
      $("#reservation_submit").attr("value", text)
