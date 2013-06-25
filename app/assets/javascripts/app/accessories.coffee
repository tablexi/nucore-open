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
    console.debug(enabled, $row)
    $row.toggleClass('disabled', !enabled)
    $input = $row.find('input').not(checkbox)
    $input.prop('disabled', !enabled || $input.data('always-disabled') == true)
