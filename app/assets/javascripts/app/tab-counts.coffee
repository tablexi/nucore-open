$ ->

  # Look at the main navigation bar to see if we're in orders or reservations
  currentSection = () ->
    active_tab = $('.navbar-static-top .active').attr('id')
    return unless active_tab?

    if active_tab.indexOf('reservations') > -1
      'reservations'
    else
      'orders'

  loadTabCounts = () ->
    tabs = []
    $('li:not(.active) .js-tab-counts').each ->
      if this.id != ""
        tabs.push(this.id)
        # Add a spinner
        $(this).append('<span class="updating"></span>')

    if tabs.length > 0
      base = FACILITY_PATH

      section = currentSection()
      return unless section

      base += "/#{section}/"

      $.ajax {
        url: base + 'tab_counts',
        dataType: 'json',
        data: { tabs: tabs },
        success: (data, textStatus, xhr) ->
          for i in tabs
            element = $(".js-tab-counts##{i} .updating")
            element.removeClass('updating')
            element.text("(#{data[i]})").addClass('updated') if data[i]?
      }

  loadTabCounts()