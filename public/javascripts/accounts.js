$(function(){
  function toggleInputs() {
    var class_select = $("#class_type");
    var class_type   = class_select.val();

    $('.account_type_fields').each(function() {
      $(this).toggle($(this).hasClass(class_type));
    });

    $('.' + class_type + ' .affiliate').trigger('change');
  }

  function toggleAffiliate() {
    $('.affiliate_other').toggle($('.affiliate:visible').val() == 'Other')
  }

  $("#datepicker").datepicker({minDate:+0, maxDate:'+3y', dateFormat: 'mm/dd/yy'});

  $("#class_type").change(function() {
    toggleInputs();
  });

  $('.affiliate').change(function() {
    toggleAffiliate();
  });

  toggleInputs();

});
