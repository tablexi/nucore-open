class TabbableReports
  constructor: (@$element) ->
    return unless @$element.length > 0
    @$tabs = @$element.find('#tabs')
    @init_tabs()
    @init_form()
    @init_pagination()

  update_parameters: ->
    @update_href $(@current_tab())
    @refresh_tab()

  refresh_tab: ->
    index = @$tabs.tabs('option', 'active')
    current_tab = @$tabs.find('[role=tab]')[index]
    @$tabs.tabs('load', index)

  current_tab: ->
    index = @$tabs.tabs('option', 'active')
    current_tab = @$tabs.find('[role=tab]')[index]

  init_tabs: ->
    @$tabs.find('a').each ->
      $(this).parent('li').data('base-href', $(this).attr('href'))

    self = this
    @$tabs.tabs({
      active: window.activeTab
      beforeActivate: (event, ui) ->
        # if there was an old error message, fade it out now
        $('#error-msg').fadeOut();

        self.update_href ui.newTab
        true

      beforeLoad: (event, ui) ->
        ui.ajaxSettings.dataType = 'text/html'
        ui.jqXHR.error (xhr, status, error) ->
          # don't show error message if it's because of user aborting ajax request
          if status != 'abort'
            $('#error-msg').html('Sorry, but the tab could not load. Please try again soon.').show();

      load: (event, ui) ->
        self.fix_bad_dates(ui.panel)
    })

  build_query_string: ->
    "?" + @$element.serialize()

  init_form: ->
    $('#status_filter').chosen()
    $('.datepicker').datepicker()
    self = this
    @$element.find(':input').change ->
      self.update_parameters()

  update_href: (tab) ->
    base_url = tab.data('base-href')
    tab.find('a').attr('href', base_url + @build_query_string())

  # Make sure to update the date params in case they were empty or invalid
  fix_bad_dates: (panel) ->
    $('#date_start').val($(panel).find('.updated_values .date_start').text())
    $('#date_end').val($(panel).find('.updated_values .date_end').text())

  init_pagination: ->
    self = this
    $(document).on 'click', '.pagination a', ->
      self.current_tab().find('a').attr('href', $(this).attr('href'))
      self.refresh_tab()
      false

$ ->
  window.report = new TabbableReports($('#refresh-form'))
