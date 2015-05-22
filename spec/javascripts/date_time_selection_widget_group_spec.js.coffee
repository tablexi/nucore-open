#= require jquery

describe "DateTimeSelectionWidgetGroup", ->
  fixture.set '
    <form>
      <input name="date" value="11/13/2015">
      <input name="hour" value="9">
      <input name="minute" value="15">
      <input name="meridian" value="AM">
    </form>
  '

  beforeEach ->
    $date = $("input[name=date]", fixture.el)
    $hour = $("input[name=hour]", fixture.el)
    $minute = $("input[name=minute]", fixture.el)
    $meridian = $("input[name=meridian]", fixture.el)
    reserveInterval = 15

    @subject = new DateTimeSelectionWidgetGroup(
      $date, $hour, $minute, $meridian, reserveInterval
    )

  describe "#getDateTime", ->
    it "converts existing field values into the expected Date object", ->
      expect(@subject.getDateTime()).toEqual(new Date(2015, 10, 13, 9, 15))

    describe "when the date value is changed", ->
      beforeEach -> $("input[name=date]", fixture.el).val("3/2/2016")

      it "converts the new field values into the expected Date object", ->
        expect(@subject.getDateTime()).toEqual(new Date(2016, 2, 2, 9, 15))

    describe "when the hour value is changed", ->
      describe "3 AM", ->
        beforeEach ->
          $("input[name=hour]", fixture.el).val(3)
          $("input[name=meridian]", fixture.el).val("AM")

        it "converts the new field values into the expected Date object", ->
          expect(@subject.getDateTime())
            .toEqual(new Date(2015, 10, 13, 3, 15))

      describe "4 PM", ->
        beforeEach ->
          $("input[name=hour]", fixture.el).val(4)
          $("input[name=meridian]", fixture.el).val("PM")

        it "converts the new field values into the expected Date object", ->
          expect(@subject.getDateTime())
            .toEqual(new Date(2015, 10, 13, 16, 15))

      describe "midnight", ->
        beforeEach ->
          $("input[name=hour]", fixture.el).val(12)
          $("input[name=meridian]", fixture.el).val("AM")

        it "converts the new field values into the expected Date object", ->
          expect(@subject.getDateTime())
            .toEqual(new Date(2015, 10, 13, 0, 15))

      describe "noon", ->
        beforeEach ->
          $("input[name=hour]", fixture.el).val(12)
          $("input[name=meridian]", fixture.el).val("PM")

        it "converts the new field values into the expected Date object", ->
          expect(@subject.getDateTime())
            .toEqual(new Date(2015, 10, 13, 12, 15))

    describe "when the minute value is changed", ->
      for minute in [0..59] by 15
        describe "to #{minute}", ->
          beforeEach -> $("input[name=minute]", fixture.el).val(minute)

          it "converts the new field values into the expected Date object", ->
            expect(@subject.getDateTime())
              .toEqual(new Date(2015, 10, 13, 9, minute))

  describe "#setDateTime", ->
    describe "when the time is before noon", ->
      beforeEach -> @subject.setDateTime(new Date(2016, 2, 2, 11, 45))

      it "sets itself to the expected Date object", ->
        expect(@subject.getDateTime()).toEqual(new Date(2016, 2, 2, 11, 45))

      it "sets the date field", ->
        expect($("input[name=date]", fixture.el).val()).toEqual("3/2/2016")

      it "sets the hour field", ->
        expect($("input[name=hour]", fixture.el).val()).toEqual("11")

      it "sets the minute field", ->
        expect($("input[name=minute]", fixture.el).val()).toEqual("45")

      it "sets the meridian field", ->
        expect($("input[name=meridian]", fixture.el).val()).toEqual("AM")

    describe "when the time is after noon", ->
      beforeEach -> @subject.setDateTime(new Date(2016, 2, 2, 13, 45))

      it "sets itself to the expected Date object", ->
        expect(@subject.getDateTime()).toEqual(new Date(2016, 2, 2, 13, 45))

      it "sets the date field", ->
        expect($("input[name=date]", fixture.el).val()).toEqual("3/2/2016")

      it "sets the hour field", ->
        expect($("input[name=hour]", fixture.el).val()).toEqual("1")

      it "sets the minute field", ->
        expect($("input[name=minute]", fixture.el).val()).toEqual("45")

      it "sets the meridian field", ->
        expect($("input[name=meridian]", fixture.el).val()).toEqual("PM")

    describe "when the time is noon hour", ->
      beforeEach -> @subject.setDateTime(new Date(2016, 2, 2, 12, 45))

      it "sets itself to the right datetime", ->
        expect($("input[name=date]", fixture.el).val()).toEqual("3/2/2016")
        expect($("input[name=hour]", fixture.el).val()).toEqual("12")
        expect($("input[name=meridian]", fixture.el).val()).toEqual("PM")

    describe "when the time is midnight hour", ->
      beforeEach -> @subject.setDateTime(new Date(2016, 2, 2, 0, 45))

      it "sets itself to the right datetime", ->
        expect($("input[name=date]", fixture.el).val()).toEqual("3/2/2016")
        expect($("input[name=hour]", fixture.el).val()).toEqual("12")
        expect($("input[name=meridian]", fixture.el).val()).toEqual("AM")

    describe "when the time is not aligned to the reserveInterval", ->
      beforeEach -> @subject.setDateTime(new Date(2016, 2, 2, 13, 39))

      it "rounds down to the previous valid interval", ->
        expect(@subject.getDateTime()).toEqual(new Date(2016, 2, 2, 13, 30))
        expect($("input[name=minute]", fixture.el).val()).toEqual("30")

  xdescribe "#change", ->
    it "TODO: needs tests"
