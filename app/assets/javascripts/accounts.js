$(function(){
  function toggleInputs() {
    var class_select = $("#class_type");
    var class_type   = class_select.val();

    $('.account_type_fields').each(function() {
      var visible = $(this).hasClass(class_type);
      $(this).toggle(visible);
      $(this).find('input, select, textarea').prop('disabled', !visible);
    });

    $('.' + class_type + ' .affiliate').trigger('change');
  }

  function toggleAffiliate() {
    $('.affiliate_other').toggle($('.affiliate:visible option:selected').text() == 'Other')
  }

  $("#datepicker").datepicker({minDate:+0, maxDate:'+3y', dateFormat: 'mm/dd/yy'});

  $("#class_type").change(function() {
    toggleInputs();
  });

  $('.affiliate').change(function() {
    toggleAffiliate();
  });

  toggleInputs();

  // Autotab
  $('.account_number_field :input[maxlength]').keyup(function(evt) {
    $this = $(this);
    // if it's a number key
    if (evt.keyCode >= 96 && evt.keyCode <= 105) {
      if ($this.val().length >= $this.attr('maxlength')) {
        var inputs = $this.closest('form').find(':input');
        inputs.eq( inputs.index(this)+ 1 ).focus();
      }
    }
  });
});
