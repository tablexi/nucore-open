$ ->
  $('#selected_account').change ->
    $(this).closest('form').submit();
