$ ->
  $(".datepicker, .datepicker__data").on "change", (e) ->
    $input = $(e.target)

    format = $input.datepicker("option", "dateFormat")

    try
      $.datepicker.parseDate(format, $input.val())
      $input.closest(".control-group").removeClass("error")
    catch
      $input.closest(".control-group").addClass("error")

