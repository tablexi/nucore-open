var ReservationCalendar = function() {}

ReservationCalendar.prototype = {
  init: function($calendar, $reservationForm) {
    this.id = $reservationForm.data("reservation-id") || "new";
    this.$calendar = $calendar;
    this.$reservationForm = $reservationForm;
    self = this; // so the handlers have access to this
    options = {
      eventDrop: this._handleEventDragDrop,
      eventResize: this._handleEventDragDrop,
      dayClick: this._handleClick,
      eventOverlap: false,
    }

    $calendar.on("calendar:rendered", this._removeSelfFromSource);
    new FullCalendarConfig($calendar, options).init();
    this._addReservationFormListerer();
  },

  renderCurrentEvent: function(start, end) {
    if (this.currentEvent) {
      this.$calendar.fullCalendar("removeEvents", [this.currentEvent.id]);
    }
    this.currentEvent = {
      id: "_currentEvent",
      title: "My Reservation",
      start: start,
      end: end,
      color: '#378006',
      allDay: false,
      editable: true
    };
   this.$calendar.fullCalendar('renderEvent', this.currentEvent, true);
  },

  // When in edit mode,this will remove the current reservation from the JSON
  // source so we can replace it with our currentEvent.
  _removeSelfFromSource: function() {
    self.$calendar.fullCalendar("removeEvents", [self.id]);
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
