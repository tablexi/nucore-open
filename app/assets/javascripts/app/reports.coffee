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
        # Show a loading message so the user sees immediate feedback
        # that their action is being applied
        ui.panel.html('<span class="updating"></span> Loading...')
        ui.ajaxSettings.dataType = 'text/html'
        ui.jqXHR.error (xhr, status, error) ->
          # don't show error message if it's because of user aborting ajax request
          if status != 'abort'
            $('#error-msg').html('Sorry, but the tab could not load. Please try again soon.').show();

      load: (event, ui) ->
        self.fix_bad_dates(ui.panel)
        self.update_export_urls()
    })

  build_query_string: ->
    "?" + @$element.serialize()

  tab_url: (tab) ->
    $(tab).data('base-href') + @build_query_string()

  init_form: ->
    $('#status_filter').chosen() if $('#status_filter').length
    $('.datepicker').datepicker()
    self = this
    @$element.find(':input').change ->
      self.update_parameters()

  update_href: (tab) ->
    tab.find('a').attr('href', @tab_url(tab))

  # Make sure to update the date params in case they were empty or invalid
  fix_bad_dates: (panel) ->
    $('#date_start').val($(panel).find('.updated_values .date_start').text())
    $('#date_end').val($(panel).find('.updated_values .date_end').text())

  init_pagination: ->
    self = this
    $(document).on 'click', '.pagination a', (evt) ->
      evt.preventDefault()
      $(self.current_tab()).find('a').attr('href', $(this).attr('href'))
      self.refresh_tab()

  update_export_urls: ->
    url = @tab_url(@current_tab())
    $('#export').attr('href', url + '&export_id=report&format=csv');
    $('#export-all').attr('href', url + '&export_id=report_data&format=csv');

$ ->
  window.report = new TabbableReports($('#refresh-form'))
