$(document).ready(function() {
  $('#calendar').fullCalendar({
                  editable: false,
                  defaultView: 'agendaWeek',
                  allDaySlot: false,
                  header: {left: '', center: 'title', right: 'prev,next today agendaDay,agendaWeek,month'},
                  events: events_path,
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
                })
})
