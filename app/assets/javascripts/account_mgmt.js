$(function() {
  $('#selected_account').change(function(){
    $(this).closest('form').submit();
  });
});
