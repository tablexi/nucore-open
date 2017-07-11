
$ ->
  window.defaultCalendarOptions = {
    editable: false
    defaultView: 'agendaWeek'
    allDaySlot: false
    events: events_path
    loading: (isLoading, view) ->
      if isLoading
        $("#overlay").addClass('on').removeClass('off')
      else
        $("#overlay").addClass('off').removeClass('on')
        try
          startDate = $.fullCalendar.formatDate(view.start, "yyyyMMdd")
          endDate   = $.fullCalendar.formatDate(view.end, "yyyyMMdd")
          # check calendar start date
          if startDate < minDate
            # hide the previous button
            $("div.fc-button-prev").hide()
          else
            # show the previous button
            $("div.fc-button-prev").show()

          # check calendar end date
          if endDate > maxDate
            # hide the next button
            $("div.fc-button-next").hide()
          else
            # show the next button
            $("div.fc-button-next").show()

    eventAfterRender: (event, element) ->
      tooltip = [
        $.fullCalendar.formatDate(event.start, 'h:mmTT'),
        $.fullCalendar.formatDate(event.end,   'h:mmTT')
      ].join('&ndash;') + '<br/>'

      # Default for our tooltip is to show.
      if $("#calendar").data("show-tooltip") != false
        if event.admin # administrative reservation
          tooltip += 'Admin Reservation<br/>'
        else # normal reservation
          tooltip += [
            event.name,
            event.email,
            event.product
          ].join('<br/>')

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
  }
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
