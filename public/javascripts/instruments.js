$(document).ready(function() {
  $('#calendar').fullCalendar({
                  editable: false,
                  defaultView: 'agendaWeek',
                  allDaySlot: false,
                  header: {left: '', center: 'title', right: 'prev,next today agendaDay,agendaWeek,month'},
                  events: events_path,
                  eventAfterRender: function(event, element) {
                    var tooltip = [
                      $.fullCalendar.formatDate(event.start, 'hh:mmTT'),
                      $.fullCalendar.formatDate(event.end,   'hh:mmTT')
                    ].join('&mdash;') + '<br/>';

                    if (event.admin) {// administrative reservation
                      tooltip += 'Admin Reservation<br/>';
                    } else {          // normal reservation
                      tooltip += [
                        event.name,
                        event.email
                      ].join('<br/>');
                    }
                    element.qtip({
                      content: tooltip,
                      position: {
                        corner: {
                          target:   'bottomLeft',
                          tooltip:  'topRight'
                        }
                      }
                    });
                  },
                  loading: function(isLoading, view) {
                    var startDate, endDate;
                    if (isLoading) {
                      $("#overlay").addClass('on').removeClass('off');
                    } else {
                      $("#overlay").addClass('off').removeClass('on');
                      try {
                        startDate = $.fullCalendar.formatDate(view.start, "yyyyMMdd")
                        endDate   = $.fullCalendar.formatDate(view.end, "yyyyMMdd")

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
