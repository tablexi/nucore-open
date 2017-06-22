$ ->
  $(".datepicker, .datepicker__data").on "change", (e) ->
    $input = $(e.target)

    format = $input.datepicker("option", "dateFormat")
    minDate = $input.datepicker("option", "minDate")
    maxDate = $input.datepicker("option", "maxDate")

    try
      date = $.datepicker.parseDate(format, $input.val())

      if maxDate && date > $.datepicker.parseDate(format, maxDate)
        throw new Error("Beyond maxDate")
      if minDate && date < $.datepicker.parseDate(format, minDate)
        throw new Error("Before minDate")

      $input.closest(".control-group").removeClass("error")
    catch e
      $input.closest(".control-group").addClass("error")
