class window.DateTimeSelectionWidgetGroup
  constructor: (@$dateField, @$hourField, @$minuteField, @$meridianField) ->

  getDateTime: ->
    formatter = TimeFormatter.fromString(@$dateField.val(), @$hourField.val(), @$minuteField.val(), @$meridianField.val())
    formatter.toDateTime()

  setDateTime: (dateTime) ->
    formatter = new TimeFormatter(dateTime)

    @$dateField.val(formatter.dateString())
    @$hourField.val(formatter.hour12())
    @$meridianField.val(formatter.meridian())

    @$minuteField.val(dateTime.getMinutes())

    @change()

  change: (callback) ->
    fields = [@$dateField, @$hourField, @$minuteField, @$meridianField]
    $field.change(callback) for $field in fields

  @fromFields: (form, date_field, hour_field, minute_field, meridian_field) ->
    new DateTimeSelectionWidgetGroup(
      $(form).find("[name=\"#{date_field}\"]")
      $(form).find("[name=\"#{hour_field}\"]")
      $(form).find("[name=\"#{minute_field}\"]")
      $(form).find("[name=\"#{meridian_field}\"]")
    )

class window.ReservationTimeFieldAdjustor
  constructor: (@$form, @opts, @reserveInterval = 1) ->
    @reserveStart = DateTimeSelectionWidgetGroup.fromFields(
      @$form,
      @opts["start"]...,
    )

    @reserveEnd = DateTimeSelectionWidgetGroup.fromFields(
      @$form,
      @opts["end"]...,
    )

    @durationFieldSelector = "[name=\"#{@opts["duration"]}\"]"

    @addListeners()

  durationField: ->
    @$form.find(@durationFieldSelector)

  addListeners: ->
    @reserveStart.change(@_reserveStartChangeCallback)
    @reserveEnd.change(@_reserveEndChangeCallback)
    # Trying to bind directly to the element can cause timeing problems
    @$form.on "change", @durationFieldSelector, @_durationChangeCallback

  # in minutes
  calculateDuration: ->
    (@reserveEnd.getDateTime() - @reserveStart.getDateTime()) / 60 / 1000

  _durationChangeCallback: =>
    durationMinutes = @durationField().val()

    if durationMinutes % @reserveInterval == 0
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime().addMinutes(durationMinutes))
      @_changed()

  _reserveEndChangeCallback: =>
    if @calculateDuration() >= 0
      @durationField().val(@calculateDuration())
      @durationField().trigger("change")
      @_changed()
    else
      # If the duration ends up negative, i.e. end is before start,
      # set the end to the start time plus the duration specified in the box
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime()
          .addMinutes(@durationField().val()))

  _reserveStartChangeCallback: =>
    duration = @durationField().val()
    # Changing the start time will leave the duration alone, but change the
    # end time to X minutes after the start time
    endTime = @reserveStart.getDateTime().addMinutes(duration)

    @reserveEnd.setDateTime(endTime)
    @_changed()

  _changed: =>
    @$form.trigger("order_management.times_changed")

$ ->
  # reserveInterval is not set on admin reservation pages, and we don't need these handlers there
  if reserveInterval?
    $("form.new_reservation, form.edit_reservation").each (i, elem) ->
      new ReservationTimeFieldAdjustor(
        $(elem),
        "start": [
          "reservation[reserve_start_date]",
          "reservation[reserve_start_hour]",
          "reservation[reserve_start_min]",
          "reservation[reserve_start_meridian]"
        ]
        "end": [
          "reservation[reserve_end_date]",
          "reservation[reserve_end_hour]",
          "reservation[reserve_end_min]",
          "reservation[reserve_end_meridian]"
        ]
        "duration": "reservation[duration_mins]"
      reserveInterval)
