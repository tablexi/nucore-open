$(function() {
    $('#selected_account').change(function(){
      $(this).closest('form').submit();
    });

    $('#toggle').change(function(){
      var toggle=$(this);

      $('input:checkbox').each(function(){
        $(this).attr('checked', toggle.attr('checked'));
      });
    });
});