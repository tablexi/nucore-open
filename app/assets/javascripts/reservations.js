$(document).ready(function() {
  // initialize fullcalendar
  var calendarOptions = {
    editable: false,
    defaultView: 'agendaWeek',
    allDaySlot: false,
    events: events_path,
    eventAfterRender: function(event, element) {
      var tooltip = [
        $.fullCalendar.formatDate(event.start, 'hh:mmTT'),
        $.fullCalendar.formatDate(event.end,   'hh:mmTT')
      ].join('&mdash;') + '<br/>';

      if (typeof withDetails != 'undefined' && withDetails) {
        if (event.admin) {  // administrative reservation
          tooltip += 'Admin Reservation<br/>';
        } else {            // normal reservation
          tooltip += [
            event.name,
            event.email
          ].join('<br/>');
        }

        // create the tooltip
        if (element.qtip) {
          $(element).qtip({
            content: tooltip,
            position: {
              corner: {
                target:   'bottomLeft',
                tooltip:  'topRight'
              }
            }
          });
        }
      }
    },
    minTime: minTime,
    maxTime: maxTime,
    height: (maxTime - minTime)*42 + 75,
    loading: function(isLoading, view) {
      if (isLoading) {
        $("#overlay").addClass('on').removeClass('off');
      } else {
        $("#overlay").addClass('off').removeClass('on');
        try {
          var startDate = $.fullCalendar.formatDate(view.start, "yyyyMMdd")
          var endDate   = $.fullCalendar.formatDate(view.end, "yyyyMMdd")
          // check calendar start date
          if (startDate < minDate) {
            // hide the previous button
            $("div.fc-button-prev").hide();
          } else {
            // show the previous button
            $("div.fc-button-prev").show();
          }
          // check calendar end date
          if (endDate > maxDate) {
            // hide the next button
            $("div.fc-button-next").hide();
          } else {
            // show the next button
            $("div.fc-button-next").show();
          }
        } catch(error) {}
      }
    }

  };
  if (window.initialDate) {
	  var d = new Date(Date.parse(initialDate));
	  $.extend(calendarOptions, {year: d.getFullYear(), month: d.getMonth(), date: d.getDate()});
  }

  $('#calendar').fullCalendar(calendarOptions);

  init_datepickers();

  // initialize datepicker
  function init_datepickers() {
    if (typeof minDaysFromNow == "undefined") {
      window['minDaysFromNow'] = 0;
    }
    $("#datepicker").datepicker({'minDate':minDaysFromNow, 'maxDate':maxDaysFromNow});

    $('.datepicker').each(function(){
      $(this).datepicker({'minDate':minDaysFromNow, 'maxDate':maxDaysFromNow})
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

  //$("div.fc-button-prev").hide();
});

