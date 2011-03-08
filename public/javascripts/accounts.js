$(document).ready(function() {
  $("#datepicker").datepicker({minDate:+0, maxDate:'+3y', dateFormat: 'mm/dd/yy'});
  
  function toggleInputs() {
    var class_select = $("#class_type");
    var class_type   = class_select.val();
    class_select.closest("ul").find(":input").each(function() {
      var input = $(this);
      if (input.hasClass(class_type)) {
        input.attr('disabled', false);
        input.closest("li").show();
      } else if (!input.hasClass('show_always')) {
        input.attr('disabled', true);
        input.closest("li").hide();
      }
    });
  }
  
  $("#class_type").change(function() {
    toggleInputs();
  });
  
  toggleInputs();
});
