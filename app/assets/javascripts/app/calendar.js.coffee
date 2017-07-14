class window.FullCalendarConfig
  constructor: (@$element) ->

  options: ->
    editable: false
    defaultView: 'agendaWeek'
    allDaySlot: false
    events: events_path
    loading: (isLoading, view) =>
      @toggleOverlay(isLoading)
      @toggleNextPrev(view) if !isLoading
    eventAfterRender: @buildTooltip

  toggleOverlay: (isLoading) ->
    if isLoading
      $("#overlay").addClass("on").removeClass("off")
    else
      $("#overlay").addClass("off").removeClass("on")

  toggleNextPrev: (view) ->
    try
      startDate = $.fullCalendar.formatDate(view.start, "yyyyMMdd")
      endDate   = $.fullCalendar.formatDate(view.end, "yyyyMMdd")
      # check calendar start date

      if startDate < window.minDate
        # hide the previous button
        $("div.fc-button-prev").hide()
      else
        # show the previous button
        $("div.fc-button-prev").show()

      # check calendar end date
      if endDate > window.maxDate
        # hide the next button
        $("div.fc-button-next").hide()
      else
        # show the next button
        $("div.fc-button-next").show()
    catch e
      console.debug e

  buildTooltip: (event, element) ->
    tooltip = [
      $.fullCalendar.formatDate(event.start, 'h:mmTT'),
      $.fullCalendar.formatDate(event.end,   'h:mmTT')
    ].join('&ndash;') + '<br/>'

    # Default for our tooltip is to show.
    if $("#calendar").data("show-tooltip") != false
      tooltip += [
        event.title,
        event.email,
        event.product,
      ].filter(
        (e) -> e? # remove undefined values
      ).join('<br/>')

      # create the tooltip
      if element.qtip
        $(element).qtip(
          content: tooltip,
          style:
            classes: "qtip-light"
          position:
            at:  'bottom left'
            my:  'topRight'
        )

$ ->
  window.defaultCalendarOptions = new FullCalendarConfig($("#calendar")).options()
  if window.minTime?
    defaultCalendarOptions.minTime = window.minTime
  if window.maxTime?
    defaultCalendarOptions.maxTime = window.maxTime
    defaultCalendarOptions.height = 42*(maxTime - minTime) + 75
  if window.initialDate
    d = Date.parse(initialDate)
    $.extend(defaultCalendarOptions,
      year: d.getFullYear()
      month: d.getMonth()
      date: d.getDate())
