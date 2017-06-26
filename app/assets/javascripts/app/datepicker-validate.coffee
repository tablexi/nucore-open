# Activated by DatePickerData
class window.DatePickerValidate
  constructor: (pickerSelector) ->
    @$picker = $(pickerSelector)

  activate: ->
    unless @$picker.data("datepicker-validate-enabled")
      @$picker.on("change", @dateChanged)
              .data("datepicker-validate-enabled", true)

  dateChanged: (e) =>
    $input = $(e.target)

    format = $input.datepicker("option", "dateFormat")
    minDate = @_parseDate($input.datepicker("option", "minDate"), format)
    maxDate = @_parseDate($input.datepicker("option", "maxDate"), format)

    try
      date = @_parseDate($input.val(), format)

      if maxDate && date > maxDate
        throw new Error("cannot be after #{@_formatDate(maxDate)}")
      if minDate && date < minDate
        throw new Error("cannot be before #{@_formatDate(minDate)}")

      $input.closest(".control-group").removeClass("error")
      $input.siblings(".help-inline").remove()
    catch e
      $input.closest(".control-group").addClass("error")
      $input.after("<span class='help-inline'>#{e.message}</span>")

  _parseDate: (dateOrString, format) ->
    if typeof dateOrString is "string"
      try
        $.datepicker.parseDate(format, dateOrString)
      catch e
        throw new Error("invalid date format", e)
    else
      dateOrString

  _formatDate: (date) ->
    new TimeFormatter(date).dateString()
