$(document).ready(function() {
  const calendar = $("#calendar");
  const defaultView = calendar.data('defaultView');
  const showCanceled = $("#show_canceled");

  const header = { left: 'title', center: '', right: '' };

  let defaultRightHeader = 'prev,next today';

  if (defaultView != 'month') {
    defaultRightHeader = `${defaultRightHeader} agendaDay,agendaWeek,month`;
  }

  header.right = defaultRightHeader;

  const options = { header };

  if (showCanceled.length > 0) {
    options.events = {
      url: events_path,
      data: () => ({ show_canceled: showCanceled.is(":checked") }),
    };

    showCanceled.on("change", () => calendar.fullCalendar("refetchEvents"));
  }

  new FullCalendarConfig(calendar, options).init();
});
