class window.FullCalendarConfig
  constructor: (@$element, @customOptions = {}) ->

  init: ->
    @$element.fullCalendar($.extend(@options(), @customOptions))

  options: ->
    options = @baseOptions()
    if window.minTime?
      options.minTime = "#{window.minTime}:00:00"
    if window.maxTime?
      options.maxTime = "#{window.maxTime}:00:00"
      options.height = 42 * (maxTime - minTime) + 52
    if window.initialDate
      options.defaultDate = window.initialDate
    options

  baseOptions: ->
    editable: false
    defaultView: "agendaWeek"
    allDaySlot: false
    events: events_path
    loading: (isLoading, view) =>
      @toggleOverlay(isLoading)

    eventAfterRender: @buildTooltip
    eventAfterAllRender: (view) =>
      @$element.trigger("calendar:rendered")
      @toggleNextPrev(view)

  toggleOverlay: (isLoading) ->
    if isLoading
      $("#overlay").addClass("on").removeClass("off")
    else
      $("#overlay").addClass("off").removeClass("on")

  toggleNextPrev: (view) ->
    try
      startDate = @formatCalendarDate(view.start)
      endDate = @formatCalendarDate(view.end)

      $(".fc-button-prev").toggleClass("fc-state-disabled", startDate < window.minDate)
      $(".fc-button-next").toggleClass("fc-state-disabled", endDate > window.maxDate)

  buildTooltip: (event, element) =>
    # Default for our tooltip is to show, even if data-attribute is undefined.
    # Only hide if explicitly set to false.
    if $("#calendar").data("show-tooltip") != false
      tooltip = [
        @formattedEventPeriod(event),
        event.title,
        event.email,
        event.product,
        event.expiration,
        event.user_note,
        @linkToEditOrder(event)
      ].filter(
        (e) -> e? # remove undefined values
      ).join("<br/>")

      # create the tooltip
      if element.qtip
        $(element).qtip(
          content: tooltip,
          style:
            classes: "qtip-light"
          position:
            at: "bottom left"
            my: "topRight"
          hide:
            fixed: true
            delay: 300
        )

  # window.minDate/maxDate are strings formatted like 20170714
  formatCalendarDate: (date) ->
    $.fullCalendar.formatDate(date, "yyyyMMdd")

  formattedEventPeriod: (event) ->
    [event.start, event.end].
      map((date) -> $.fullCalendar.formatDate(date, "h:mmA")).
      join("&ndash;")

  linkToEditOrder: (event) ->
    "<a href='#{orders_path_base}/#{event.orderId}'>Edit</a>"
