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
  }).trigger('change');
  
  $('input[type=text]').keyup(function(e) {
    setinternalcost(this);
  });

  function getMasterUsageRate() {
    return parseFloat($('input.master_usage_cost.usage_rate').val());
  }

  function refreshCosts() {
    $('.master_minimum_cost').each(function (index, element) {
      setinternalcost(element);
    });
  }

  function setUsageSubsidy(usageAdjustmentElement, usageSubsidy) {
    $(usageAdjustmentElement).parents('tr').find('span.minimum_cost').data('usageSubsidy', usageSubsidy.toFixed(2));
  }

  function updateUsageSubsidy(usageAdjustmentElement) {
    var usageAdjustment = parseFloat(usageAdjustmentElement.value)
    if (isFinite(usageAdjustment)) {
      var usageRate = getMasterUsageRate();
      if (isFinite(usageRate)) {
        var usageSubsidy = usageAdjustment / usageRate;
        if (isFinite(usageSubsidy)) {
          setUsageSubsidy(usageAdjustmentElement, usageSubsidy);
          refreshCosts();
        }
      }
    }
  }

  function deriveAdjustedCost(unadjustedCost, usageSubsidyString) {
    var usageSubsidy = parseFloat(usageSubsidyString);
    if (isFinite(usageSubsidy)) {
      return (unadjustedCost * (1.0 - usageSubsidy)).toFixed(2);
    }
    else {
      return unadjustedCost;
    }
  }

  function setinternalcost(o) {
    if (o.className.match(/master_(\S+_cost)/)) {
      var desiredClass = RegExp.$1;
      var $spanElements = $('span.' + desiredClass);
      var cost = deriveAdjustedCost(o.value, $spanElements.data('usageSubsidy'));
      $spanElements.html(cost);
      $('input[type=hidden].' + desiredClass).val(cost);
    }
    else if (o.className.match(/\busage_adjustment\b/)) {
      updateUsageSubsidy(o);
    }
  }

  function toggleGroupFields($checkbox) {
    $cells = $checkbox.parents('tr').find('td');
    var isDisabled = !$checkbox.prop('checked');
    $cells.toggleClass('disabled', isDisabled);
    $cells.find('input[type=text], input[type=hidden]').each(function() {
      // If we're hiding the value, store it so we can retreive it later
      if ($(this).val()) $(this).data('original-value', $(this).val());
      $(this).val(isDisabled ? '' : $(this).data('original-value')).prop('disabled', isDisabled);
    });
  }
});

