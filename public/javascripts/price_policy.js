$(document).ready(function() {
  $(function() {
    $("#start_datepicker").datepicker({minDate: null});
    $("#expire_datepicker").datepicker({minDate: null});
  });
  
  $('#interval').change(function() {
    int_value = $(this).val();
    interval  = int_value > 1 ? int_value + " minutes" : int_value + " minute";
    $('span.interval_replace').each( function() {
      $(this).html(interval);
    });  
  });
  
  if ($('#interval').length) {
    int_value = $('#interval').val();
    interval  = int_value > 1 ? int_value + " minutes" : int_value + " minute";
    $('span.interval_replace').each( function() {
      $(this).html(interval);
    });
  }

  $('.can_purchase').change(function(e) {
    toggleGroupFields($(this));
  }).trigger("change");


  $('input[type=text]').change(function(e) {
    setinternalcost(this);
  });
  
  $('input[type=text]').keyup(function(e) {
    setinternalcost(this);
  });

  function setinternalcost(o) {
    if (o.className.match(/master_(\S+_cost)/)) {
      var desiredClass = RegExp.$1;
      $('span.' + desiredClass).each(function(i, element) {
        element.innerHTML = o.value;
      });
      $('input[type=hidden].' + desiredClass).each(function(i, element) {
        element.value = o.value;
      });
    }
  }

  function toggleGroupFields($checkbox) {
    $cells = $checkbox.parents('tr').find('td');
    $cells.toggleClass('disabled', !$checkbox.prop('checked'));
    $cells.find('input[type=text], input[type=hidden]').val('').prop('disabled', !$checkbox.prop('checked'));
  }
});

