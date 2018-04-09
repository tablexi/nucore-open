var ReservationCalendar = function() {}

ReservationCalendar.prototype = {
  init: function($calendar, $reservationForm) {
    this.id = 1234;
    this.$calendar = $calendar;
    this.$reservationForm = $reservationForm;
    self = this; // so the handlers have access to this
    options = {
      eventDrop: this._handleEventDragDrop,
      eventResize: this._handleEventDragDrop,
      dayClick: this._handleClick,
      eventOverlap: false,
    }

    new FullCalendarConfig($calendar, options).init();
    this._addReservationFormListerer();
  },

  renderCurrentEvent: function(start, end) {
    if (this.currentEvent) {
      this.$calendar.fullCalendar("removeEvents", [this.currentEvent.id]);
    }
    this.currentEvent = {
      id: this.id,
      title: "My New Reservation",
      start: start,
      end: end,
      color: '#378006',
      allDay: false,
      editable: true
    };
   this.$calendar.fullCalendar('renderEvent', this.currentEvent, true);
  },

  _addReservationFormListerer: function() {
    self = this;
    this.$reservationForm.on("reservation:times_changed", function(evt, data) {
      self.renderCurrentEvent(data.start, data.end);
    }).trigger("reservation:set_times", {});
  },

  _handleEventDragDrop: function(event, delta, revertFunc) {
    data = {
      start: self._fixTimezone(event.start),
      end:  self._fixTimezone(event.end),
    }
    self.$reservationForm.trigger("reservation:set_times", data);
  },

  _handleClick: function(date, jsEvent, view, resourceObj) {
    data = { start: self._fixTimezone(date) };
    self.$reservationForm.trigger("reservation:set_times", data);
  },

  // make sure we're in the browser's timezone
  _fixTimezone: function(date) {
    return moment(date.format());
  }

}
