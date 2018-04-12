var ReservationCalendar = function() {}

ReservationCalendar.prototype = {
  init: function($calendar, $reservationForm) {
    this.id = $reservationForm.data("reservation-id") || "new";
    this.$calendar = $calendar;
    this.$reservationForm = $reservationForm;

    if ($calendar.data("drag-and-drop-enabled")) {
      self = this; // so our callbacks have access to this object

      fullCalendarOptions = {
        eventDrop: this._handleEventDragDrop,
        eventResize: this._handleEventDragDrop,
        dayClick: this._handleClick,
        eventOverlap: false,
      }

      new FullCalendarConfig($calendar, fullCalendarOptions).init();
      $calendar.on("calendar:rendered", this._removeSelfFromSource);
      this._addReservationFormListener();
    } else {
      console.debug("HELLO");
      new FullCalendarConfig($calendar).init();
    }
  },

  renderCurrentEvent: function(start, end) {
    // It was easier to remove the old one and create a new one rather than update
    // it and get fullCalendar to re-render it.
    if (this.currentEvent) {
      this.$calendar.fullCalendar("removeEvents", [this.currentEvent.id]);
    }
    this.currentEvent = {
      id: "_currentEvent",
      title: "My Reservation",
      start: start,
      end: end,
      color: "#378006",
      allDay: false,
      startEditable: this._isStartEditable(),
      durationEditable: true
    };
   this.$calendar.fullCalendar("renderEvent", this.currentEvent, true);
  },

  _addReservationFormListener: function() {
    self = this;
    this.$reservationForm.on("reservation:times_changed", function(evt, data) {
      self.renderCurrentEvent(data.start, data.end);
    }).trigger("reservation:set_times", {});
  },

  // When in edit mode,this will remove the current reservation from the JSON
  // source so we can replace it with our currentEvent.
  _removeSelfFromSource: function() {
    self.$calendar.fullCalendar("removeEvents", [self.id]);
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

  // make sure were in the browser's timezone
  _fixTimezone: function(date) {
    return moment(date.format());
  },

  // Defaults to true
  _isStartEditable: function() {
    return this.$calendar.data("start-editable");
  }

}
