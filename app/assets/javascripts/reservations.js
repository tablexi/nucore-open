$(document).ready(function() {

  new FullCalendarConfig($("#calendar")).init()

  init_datepickers();

  // initialize datepicker
  function init_datepickers() {
    if (typeof minDaysFromNow == "undefined") {
      window['minDaysFromNow'] = 0;
    }
    $("#datepicker").datepicker();

    $('.datepicker').each(function(){
      $(this).datepicker()
      		.change(function() {
      			var d = new Date(Date.parse($(this).val()));
      			$('#calendar').fullCalendar('gotoDate', d);


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

  function setDateInPicker(picker, date) {
    var dateFormat = picker.datepicker('option', 'dateFormat');
    picker.val($.datepicker.formatDate(dateFormat, date));
  }
  function setTimeInPickers(id_prefix, date) {
    var hour = date.getHours() % 12;
    var ampm = date.getHours() < 12 ? 'AM' : 'PM';
    if (hour == 0) hour = 12;
    $('#' + id_prefix + '_hour').val(hour);
    $('#' + id_prefix + '_min').val(date.getMinutes());
    $('#' + id_prefix + '_meridian').val(ampm);
  }
  $('.copy_actual_from_reservation a').click(copyReservationTimeIntoActual);

});

