class window.TimeFormatter
  constructor: (@dateTime) ->

  hour12: ->
    hour = @hour24() % 12
    hour = 12 if hour == 0
    hour

  hour24: ->
    @dateTime.getHours()

  minute: ->
    @dateTime.getMinutes()

  meridian: ->
    if @hour24() < 12 then 'AM' else 'PM'

  year: ->
    @dateTime.getFullYear()

  # getMonth() returns 0-11, we want to return the more natural 1-12
  month: ->
    @dateTime.getMonth() + 1

  day: ->
    @dateTime.getDate()

  dateString: ->
    @dateTime.toString("M/d/yyyy")

  toString: ->
    @dateTime.toString()

  toDateTime: ->
    @dateTime

  @fromString: (date, hour, minute, meridian) ->
    parsedHour = parseInt(hour, 10) % 12
    parsedHour += 12 if meridian == "PM"

    parsedMinute = parseInt(minute, 10)

    split = date.split("/")

    # Date uses 0-11 for months
    parsedMonth = parseInt(split[0], 10) - 1
    parsedDay = parseInt(split[1], 10)
    parsedYear = parseInt(split[2], 10)

    date = new Date(parsedYear, parsedMonth, parsedDay, parsedHour, parsedMinute)
    new TimeFormatter(date)

