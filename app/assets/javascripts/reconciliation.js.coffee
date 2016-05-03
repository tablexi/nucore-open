$ ->
  $('#selected_account').change ->
    $(@).closest('form').submit()
