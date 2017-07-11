$(document).ready(function() {
  var calendarOptions = $.extend({}, defaultCalendarOptions, {
                  header: {left: '', center: 'title', right: 'prev,next today agendaDay,agendaWeek,month'},
                });

  $('#calendar').fullCalendar(calendarOptions);
})
