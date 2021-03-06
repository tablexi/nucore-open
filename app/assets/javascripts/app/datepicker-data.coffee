class window.DatePickerData
  @activate: ->
    # This will set up a datepicker based on data attributes
    # Make sure you call `to_s` or `iso8601` on any dates you set in the views
    # to ensure the proper format.
    $pickers = $(".datepicker__data")

    $pickers.each (i, picker) ->
      $picker = $(picker)
      $picker.datepicker(
        minDate: new Date($picker.data("min-date")) # will be unbounded if not provided
        maxDate: new Date($picker.data("max-date")) # will be unbounded if not provided
      )

    new DatePickerValidate($pickers).activate()

$ ->
  DatePickerData.activate()
  AjaxModal.on_show(DatePickerData.activate)
