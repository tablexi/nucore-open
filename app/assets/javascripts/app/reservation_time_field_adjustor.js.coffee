class window.DateTimeSelectionWidgetGroup
  constructor: (@$dateField, @$hourField, @$minuteField, @$meridianField, @reserveInterval) ->

  getDateTime: ->
    formatter = TimeFormatter.fromString(@$dateField.val(), @$hourField.val(), @$minuteField.val(), @$meridianField.val())
    formatter.toDateTime()

  setDateTime: (dateTime) ->
    formatter = new TimeFormatter(dateTime)

    @$dateField.val(formatter.dateString())
    @$hourField.val(formatter.hour12())
    @$meridianField.val(formatter.meridian())

    @$minuteField
      .val(dateTime.getMinutes() - (dateTime.getMinutes() % @reserveInterval))

    @change()

  change: (callback) ->
    fields = [@$dateField, @$hourField, @$minuteField, @$meridianField]
    $field.change(callback) for $field in fields

class window.ReservationTimeFieldAdjustor
  constructor: (@$form, @reserveInterval) ->
    @timeParser = new TimeParser() # From clockpunch
    @addListeners()

  addListeners: ->
    @reserveStart = @_widgetGroup('reserve_start')
    @reserveStart.change(@_reserveStartChangeCallback)

    @reserveEnd = @_widgetGroup('reserve_end')
    @reserveEnd.change(@_reserveEndChangeCallback)

    @$durationField = @$form.find('[name="reservation[duration_mins]"]')
    @$durationField.change(@_durationChangeCallback)

    @$durationDisplayField =
      @$form.find('[name="reservation[duration_mins]_display"]')

  _durationChangeCallback: =>
    durationMinutes = @_durationMinutes()
    if durationMinutes % @reserveInterval == 0
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime().addMinutes(durationMinutes))

  _getDuration: -> @reserveEnd.getDateTime() - @reserveStart.getDateTime()

  _durationMinutes: -> @timeParser.to_minutes(@$durationDisplayField.val())

  _reserveEndChangeCallback: =>
    duration = @_getDuration()

    if duration < 0
      # If the duration ends up negative, i.e. end is before start,
      # set the end to the start time plus the duration specified in the box
      duration = @_durationMinutes()
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime()
        .addMinutes(duration))
    @_setDurationFields()

  _reserveStartChangeCallback: =>
    duration = @_durationMinutes()
    # Changing the start time will leave the duration alone, but change the
    # end time to X minutes after the start time
    endTime = @reserveStart.getDateTime().addMinutes(duration)
    @reserveEnd.setDateTime(endTime)

  _setDurationFields:  ->
    durationMinutes = @_getDuration() / 60 / 1000

    @$durationDisplayField
      .val(@timeParser.from_minutes(durationMinutes))
      .trigger("keyup")
    @$durationField.val(durationMinutes)

  _widgetGroup: (field) =>
    new DateTimeSelectionWidgetGroup(
      @$form.find("[name=\"reservation[#{field}_date]\"]")
      @$form.find("[name=\"reservation[#{field}_hour]\"]")
      @$form.find("[name=\"reservation[#{field}_min]\"]")
      @$form.find("[name=\"reservation[#{field}_meridian]\"]")
      @reserveInterval
    )

$ ->
  # reserveInterval is not set on admin reservation pages, and we don't need these handlers there
  if reserveInterval?
    $("form.new_reservation, form.edit_reservation").each ->
      new ReservationTimeFieldAdjustor($(this), reserveInterval)
