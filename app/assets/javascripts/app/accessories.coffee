class window.AccessoryPicker
  constructor: (@$form) ->
    @init_timeinput()
    @init_checkboxes()

  init_timeinput: ->
    @$form.find('.timeinput').timeinput();

  init_checkboxes: ->
    self = this
    @$form.find('input[type=checkbox]').change ->
      self.enable_elements(this)
    .trigger('change')

  enable_elements: (checkbox) ->
    $checkbox = $(checkbox)
    enabled = $checkbox.prop('checked')
    $row = $checkbox.closest('.accessory-row')

    $row.toggleClass('disabled', !enabled)
    $input = $row.find('input').not(checkbox)
    $input.prop('disabled', !enabled || $input.data('always-disabled') == true)

class AccessoryPickerDialog
  constructor: (@$link) ->
    @hide_tooltips()
    @init_dialog_element()
    @show_dialog()
    # @fade_out()

  hide_tooltips: ->
    $('.tip').data('tooltipsy').hide() if $('.tip').length > 0

  init_dialog_element: ->
    @dialog = $('#pick_accessories_dialog')

    # build dialog if necessary
    if @dialog.length == 0
      @dialog = $('<div id="pick_accessories_dialog"/>')
      @dialog.hide()
      $("body").append(@dialog);

  show_dialog: ->
    self = this
    @dialog.on 'dialogclose', (evt) ->
      evt.preventDefault()
      window.location.reload()

    @dialog.on 'ajax:complete', 'form', (evt, xhr, status) ->
      self.handle_response(evt, xhr, status)

    @dialog.on 'submit', 'form', ->
      self.toggle_buttons(false)

    @dialog.on 'click', '#cancel-btn', (evt) ->
      evt.preventDefault()
      self.dialog.dialog('close')

    $.ajax {
      url: @$link.attr('href')
      dataType: 'html'
      success: (body) ->
        self.dialog.html(body)
        self.dialog.dialog {
          closeOnEscape: false,
          modal:         true,
          title:         'Accessories Entry',
          zIndex:        10000
        }
        @picker = new AccessoryPicker($('#accessory-form'));
    }

  toggle_buttons: (value) ->
    @dialog.find('input[type=submit]').prop('disabled', !value)

  handle_response: (e, xhr, status) ->
    e.preventDefault();
    console.debug xhr
    @dialog.html(xhr.responseText)
    console.debug 'status: ', status
    if status == 'success'
      @dialog.dialog('close')
    else
      @toggle_buttons true

  fade_out: ->
    @$link.fadeOut() unless @$link.hasClass('persistent')


$ ->
  $('body').on 'click', '.has_accessories', (evt) ->
    evt.preventDefault()
    picker = new AccessoryPickerDialog($(this))
