$(document).ready(function() {
  $(function() {
    $("#start_datepicker").datepicker({minDate: new Date()});
    $("#expire_datepicker").datepicker({minDate: new Date()});
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

  $('.restrict_purchase').each(function (i, checkBox) {
    if (checkBox.checked == true) {
      changecheckbox(checkBox);
    }
  });

  $('.restrict_purchase').change(function(e) {
    changecheckbox(this);
  });

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

  function changecheckbox(o) {
    var disable = false
    if (o.checked == true) {
      disable = true;
    }
    $(o).closest('tr').find('input').each(function (i, element) {
      if (element != o) {
        element.disabled = disable;
      }
    });
  }
});

