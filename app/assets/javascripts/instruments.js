$(document).ready(function() {
  var calendarOptions = ({
                  editable: false,
                  defaultEventMinutes: 60480, // 42 days
                  defaultView: 'agendaWeek',
                  allDaySlot: false,
                  header: {left: '', center: 'title', right: 'prev,next today agendaDay,agendaWeek,month'},
                  events: events_path,
                  eventAfterRender: function(event, element) {
                    var tooltip = $.fullCalendar.formatDate(event.start, "hh:mmTT");
                    if (event.end) {
                      tooltip += "&mdash;" + $.fullCalendar.formatDate(event.end, "hh:mmTT");
                    }
                    tooltip += "<br/>";

                    if (event.editPath) {
                      $(element)
                        .css("cursor", "pointer")
                        .on("click", function () { location.href = event.editPath });
                    }

                    if (event.admin) {// administrative reservation
                      if (event.offline) {
                        tooltip += "Offline";
                      }
                      else {
                        tooltip += 'Admin Reservation<br/>';
                      }
                    } else {          // normal reservation
                      tooltip += [
                        event.name,
                        event.email
                      ].join('<br/>');
                    }
                    element.qtip({
                      content: tooltip,
                      style: {
                        classes: "qtip-light"
                      },
                      position: {
                        at:  'bottom left',
                        my:  'topRight'
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
                });
  if (typeof minTime!='undefined') { calendarOptions.minTime = minTime; };
  if (typeof maxTime!='undefined') {
    calendarOptions.maxTime = maxTime;
    calendarOptions.height = (maxTime - minTime)*42 + 75
  }

  $('#calendar').fullCalendar(calendarOptions);
})
