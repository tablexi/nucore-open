#= require jquery

describe "ReservationTimeFieldAdjustor", ->
  fixture.set '
    <form>
      <input id="start_date" name="start[date]" value="11/13/2015">
      <input id="start_hour" name="start[hour]" value="9">
      <input id="start_minute" name="start[minute]" value="15">
      <input id="start_meridian" name="start[meridian]" value="AM">

      <input id="end_date" name="end[date]" value="11/13/2015">
      <input id="end_hour" name="end[hour]" value="10">
      <input id="end_minute" name="end[minute]" value="15">
      <input id="end_meridian" name="end[meridian]" value="AM">

      <input id="duration" name="duration" value="60">
    </form>
  '

  beforeEach =>
    @form = $("form", fixture.el)
    @subject = new ReservationTimeFieldAdjustor(
      @form,
      start: ["start[date]", "start[hour]", "start[minute]", "start[meridian]"],
      end: ["end[date]", "end[hour]", "end[minute]", "end[meridian]"],
      duration: ["duration"],
      15
    )

  it "can parse the start fields", =>
    expect(@subject.reserveStart.getDateTime()).toEqual(new Date(2015, 10, 13, 9, 15))

  it "can parse the end fields", =>
    expect(@subject.reserveEnd.getDateTime()).toEqual(new Date(2015, 10, 13, 10, 15))

  it "calculates a duration", =>
    expect(@subject.calculateDuration()).toEqual(60)

  describe "changing the start time", =>
    it "updates the end date for changing the date", =>
      $("#start_date", fixture.el).val("01/03/2015").trigger("change")
      expect(@subject.reserveEnd.getDateTime()).toEqual(new Date(2015, 0, 3, 10, 15))

    it "updates the end time for changing the hour", =>
      $("#start_hour", fixture.el).val(11).trigger("change")
      expect(@subject.reserveEnd.getDateTime()).toEqual(new Date(2015, 10, 13, 12, 15))

    it "updates the end time for changing the minute", =>
      $("#start_minute", fixture.el).val(30).trigger("change")
      expect(@subject.reserveEnd.getDateTime()).toEqual(new Date(2015, 10, 13, 10, 30))

    it "updates the end time for changing the meridian", =>
      $("#start_meridian", fixture.el).val("PM").trigger("change")
      expect(@subject.reserveEnd.getDateTime()).toEqual(new Date(2015, 10, 13, 22, 15))

    it "does not update the duration field", =>
      $("#start_date", fixture.el).val("01/03/2015").trigger("change")
      expect(@subject.calculateDuration()).toEqual(60)
      expect(@subject.durationField().val()).toEqual("60")

  describe "changing the duration", =>
    it "updates the end time", =>
      $("#duration").val("120").trigger("change")
      expect(@subject.reserveStart.getDateTime()).toEqual(new Date(2015, 10, 13, 9, 15))
      expect(@subject.reserveEnd.getDateTime()).toEqual(new Date(2015, 10, 13, 11, 15))

    it "update the time, even across days", =>
      $("#duration").val("1440").trigger("change") # 24 hours
      expect(@subject.reserveStart.getDateTime()).toEqual(new Date(2015, 10, 13, 9, 15))
      expect(@subject.reserveEnd.getDateTime()).toEqual(new Date(2015, 10, 14, 9, 15))

    it "does not update the end time if it does not match the interval", =>
      $("#duration").val("16").trigger("change")
      expect(@subject.reserveStart.getDateTime()).toEqual(new Date(2015, 10, 13, 9, 15))
      expect(@subject.reserveEnd.getDateTime()).toEqual(new Date(2015, 10, 13, 10, 15))

  describe "changing the end time", =>
    it "does not update the start time when changing the date", =>
      $("#end_date", fixture.el).val("11/14/2015").trigger("change")
      expect(@subject.reserveStart.getDateTime()).toEqual(new Date(2015, 10, 13, 9, 15))

    it "updates the duration, but not the start time, when changing the date", =>
      $("#end_date", fixture.el).val("11/14/2015").trigger("change")
      expect(@subject.calculateDuration()).toEqual(1500)
      expect(@subject.durationField().val()).toEqual("1500")

    it "updates the duration when changing the hour", =>
      $("#end_hour", fixture.el).val("11").trigger("change")
      expect(@subject.calculateDuration()).toEqual(120)
      expect(@subject.durationField().val()).toEqual("120")

    it "updates the duration when changing the minute", =>
      $("#end_minute", fixture.el).val("00").trigger("change")
      expect(@subject.calculateDuration()).toEqual(45)
      expect(@subject.durationField().val()).toEqual("45")

    it "update the duration when changing the meridian", =>
      $("#end_meridian", fixture.el).val("PM").trigger("change")
      expect(@subject.calculateDuration()).toEqual(780)
      expect(@subject.durationField().val()).toEqual("780")

    it "reverts back to the original times if date is set before the start time", =>
      $("#end_date", fixture.el).val("11/12/2015").trigger("change")
      expect(@subject.reserveStart.getDateTime()).toEqual(new Date(2015, 10, 13, 9, 15))
      expect(@subject.reserveEnd.getDateTime()).toEqual(new Date(2015, 10, 13, 10, 15))
