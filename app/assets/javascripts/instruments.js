$(document).ready(function() {
  new FullCalendarConfig($("#calendar")).init({
    header: {
      left: '',
      center: 'title',
      right: 'prev,next today agendaDay,agendaWeek,month',
    },
  });
});
