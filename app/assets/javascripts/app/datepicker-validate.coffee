$ ->
  # Parse to a date if it's a string, otherwise just return the original argument.
  # This will handle "5/6/2016", unix timestamps, and `Date`s.
  parseDate = (dateOrString, format) ->
    if typeof dateOrString is "string"
      $.datepicker.parseDate(format, dateOrString)
    else
      dateOrString

  $(".datepicker__data").on "change", (e) ->
    $input = $(e.target)

    format = $input.datepicker("option", "dateFormat")
    minDate = parseDate($input.datepicker("option", "minDate"), format)
    maxDate = parseDate($input.datepicker("option", "maxDate"), format)

    try
      date = parseDate($input.val(), format)

      if maxDate && date > maxDate
        throw "Beyond maxDate"
      if minDate && date < minDate
        throw "Before minDate"

      $input.closest(".control-group").removeClass("error")
    catch e
      $input.closest(".control-group").addClass("error")
