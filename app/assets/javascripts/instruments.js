$(document).ready(function() {
  new FullCalendarConfig($("#calendar"), {
    header: {
      left: '',
      center: 'title',
      right: 'prev,next today agendaDay,agendaWeek,month',
    }
  }).init();
});
