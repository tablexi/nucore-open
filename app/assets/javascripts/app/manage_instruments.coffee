$ ->
  target = '.edit_instrument #instrument_min_reserve_mins'

  if $(target).length
    $(target).bind 'keyup mouseup', ->
      interval = $('#instrument_reserve_interval').val()

      if $(this).val() % interval == 0
        $(this).removeClass 'interval-error'
      else
        $(this).addClass 'interval-error'

