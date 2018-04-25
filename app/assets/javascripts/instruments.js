$(document).ready(function() {
  new FullCalendarConfig($("#calendar"), {
    header: {
      left: 'title',
      center: '',
      right: 'prev,next today agendaDay,agendaWeek,month',
    }
  }).init();
});
