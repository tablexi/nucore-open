$ ->
  target = '.edit_instrument #instrument_min_reserve_mins'

  if $(target).length
    $(target).keyup ->
      interval = $('#instrument_reserve_interval').val()
      color = if $(this).val() % interval == 0 then 'black' else 'red'
      $(this).css 'color', color

