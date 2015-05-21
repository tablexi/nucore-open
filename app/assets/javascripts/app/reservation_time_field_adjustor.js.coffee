class window.DateTimeSelectionWidgetGroup
  constructor: (@$dateField, @$hourField, @$minuteField, @$meridianField, @reserveInterval) ->

  getDateTime: -> new Date(@year(), @month(), @day(), @hour(), @minute())

  year: -> parseInt(@_splitDate()[2], 10)
  month: -> parseInt(@_splitDate()[0], 10) - 1
  day: -> parseInt(@_splitDate()[1], 10)

  hour: ->
    hour = parseInt(@$hourField.val(), 10)
    hour += 12 if @$meridianField.val() == "PM"
    hour

  minute: -> parseInt(@$minuteField.val(), 10)

  setDateTime: (dateTime) ->
    @$dateField.val(dateTime.toString("M/d/yyyy"))
    if dateTime.getHours() > 12
      @$hourField.val(dateTime.getHours() - 12)
      @$meridianField.val("PM")
    else
      @$hourField.val(dateTime.getHours())
      @$meridianField.val("AM")
    @$minuteField
      .val(dateTime.getMinutes() - (dateTime.getMinutes() % @reserveInterval))
    @change()

  change: (callback) ->
    fields = [@$dateField, @$hourField, @$minuteField, @$meridianField]
    if callback
      $field.change(callback) for $field in fields
    else
      $field.change() for $field in fields

  _splitDate: -> @$dateField.val().split("/")

class window.ReservationTimeFieldAdjustor
  constructor: (@$form, @reserveInterval) ->
    @timeParser = new TimeParser()
    @addListeners()

  addListeners: ->
    @reserveStart = new DateTimeSelectionWidgetGroup(
      @$form.find('[name="reservation[reserve_start_date]"]')
      @$form.find('[name="reservation[reserve_start_hour]"]')
      @$form.find('[name="reservation[reserve_start_min]"]')
      @$form.find('[name="reservation[reserve_start_meridian]"]')
      @reserveInterval
    )

    @reserveEnd = new DateTimeSelectionWidgetGroup(
      @$form.find('[name="reservation[reserve_end_date]"]')
      @$form.find('[name="reservation[reserve_end_hour]"]')
      @$form.find('[name="reservation[reserve_end_min]"]')
      @$form.find('[name="reservation[reserve_end_meridian]"]')
      @reserveInterval
    )

    @$durationField = @$form.find('[name="reservation[duration_mins]"]')
    @$durationDisplayField =
      @$form.find('[name="reservation[duration_mins]_display"]')

    @$durationField.change(@_durationChangeCallback)
    @reserveStart.change(@_reserveStartChangeCallback)
    @reserveEnd.change(@_reserveEndChangeCallback)

  _durationChangeCallback: =>
    durationMinutes = @timeParser.to_minutes(@$durationDisplayField.val())
    if durationMinutes % @reserveInterval == 0
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime().addMinutes(durationMinutes))

  _getDuration: -> @reserveEnd.getDateTime() - @reserveStart.getDateTime()

  minimumDuration: -> @reserveInterval * 60 * 1000

  _reserveEndChangeCallback: =>
    duration = @_getDuration()
    if duration < 0
      duration = @minimumDuration()
      @reserveStart
        .setDateTime(@reserveEnd.getDateTime()
        .addMilliseconds(-1 * duration))
    @_setDurationFields(duration)

  _reserveStartChangeCallback: =>
    duration = @_getDuration()
    if duration < 0
      duration = @minimumDuration()
      @reserveEnd
        .setDateTime(@reserveStart.getDateTime()
        .addMilliseconds(duration))
    @_setDurationFields(duration)

  _setDurationFields: (duration) ->
    durationMinutes = duration / 60000
    @$durationDisplayField
      .val(@timeParser.from_minutes(durationMinutes))
      .trigger("keyup")
    @$durationField.val(durationMinutes)

$ ->
  $("form.new_reservation, form.edit_reservation").each ->
    new ReservationTimeFieldAdjustor($(this), reserveInterval)
