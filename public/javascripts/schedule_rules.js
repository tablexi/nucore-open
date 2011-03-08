$(document).ready(function() {
  $('#calendar').fullCalendar({
                  editable: false,
                  defaultView: 'agendaWeek',
                  allDaySlot: false,
                  header: {left: '', center: '', right: ''},
                  columnFormat: {week: 'ddd'},
                  events: events_path
                })
})
