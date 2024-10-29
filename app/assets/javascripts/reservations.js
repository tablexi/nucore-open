$(document).ready(function() {
  init_datepickers();

  var form = {
    isDailyBooking: $("#calendar").length == 0,
    durationDaysEl: $('[name="reservation[duration_days]"]'),
    startDateEl: $('[name="reservation[reserve_start_date]"]'),
    endDateEl: $('[name="reservation[reserve_end_date]"]'),
    endDateShownEl: $('[name="reserve_end_date_shown"]')
  };

  // initialize datepicker
  function init_datepickers() {
    if (typeof minDaysFromNow == "undefined") {
      window['minDaysFromNow'] = 0;
    }
    if (typeof maxDaysFromNow == "undefined") {
      window['maxDaysFromNow'] = 365;
    }
    $("#datepicker").datepicker({'minDate': minDaysFromNow, 'maxDate': maxDaysFromNow});

    $('.datepicker').each(function(){
      $(this).datepicker({'minDate': minDaysFromNow, 'maxDate': maxDaysFromNow})
        .change(function() {
          var d = new Date(Date.parse($(this).val()));
          if (!form.isDailyBooking) $('#calendar').fullCalendar('gotoDate', d);
        });
    });
  }

  /* Copy in actual times from reservation time */
  function copyReservationTimeIntoActual(e) {
    e.preventDefault()
    $(this).fadeOut('fast');
    // copy each reserve_xxx field to actual_xxx
    $('[name^="reservation[reserve_"]').each(function() {
      var actual_name = this.name.replace(/reserve_(.*)$/, "actual_$1");
      $("[name='" + actual_name + "']").val($(this).val());
    });

    // duration_mins doesn't follow the same pattern, so do it separately
    var newval = $('[name="reservation[duration_mins]"]').val();

    $('[name="reservation[actual_duration_mins]_display"]').val(newval).trigger('change');
  }

  /**
   * Update reservation_end_date out of duration days and start date
   */
  function updateReserveEndDate() {
    var duration = parseInt(form.durationDaysEl.val());
    var startDateEpoch = Date.parse(form.startDateEl.val());

    if (!(duration > 0 && startDateEpoch > 0)) { return; }

    var startDate = new Date(startDateEpoch);
    var endDate = new Date(startDate);

    endDate.setDate(startDate.getDate() + duration - 1);

    var dateFormat = form.startDateEl.datepicker('option', 'dateFormat');
    var dateStr = $.datepicker.formatDate(dateFormat, endDate)

    form.endDateEl.val(dateStr);
    form.endDateShownEl.val(dateStr);
  }

  $('.copy_actual_from_reservation a').click(copyReservationTimeIntoActual);

  if (form.isDailyBooking) {
    form.durationDaysEl.on('keyup', updateReserveEndDate);
    form.startDateEl.on('change', updateReserveEndDate);
  } else {
    new ReservationCalendar().init($("#calendar"), $(".js--reservationForm"));
  }
});

