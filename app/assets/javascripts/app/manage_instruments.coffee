$ ->
  target = '.edit_instrument #instrument_min_reserve_mins,.edit_instrument #instrument_max_reserve_mins'

  if $(target).length
    $(target).bind 'keyup mouseup', ->
      interval = $('#instrument_reserve_interval').val()

      if $(this).val() % interval == 0
        $(this).removeClass 'interval-error'
      else
        $(this).addClass 'interval-error'

  $('#instrument_auto_cancel_mins').change (event) ->
    $warning_node = $(".js--auto_cancel_mins-zero-warning")
    minutes = $(event.target).val() || 0

    if minutes > 0
      $warning_node.hide()
    else
      $warning_node.show()

  $('#instrument_auto_cancel_mins').change()
