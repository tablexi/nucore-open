class window.ReservationTimeChecker
  constructor: (@selector, @alertId = 'duration-alert')->
    if @validPage()
      @initAlert()
      @respondToChange()

  validPage: ->
    # These variable are not set on the admin reservation pages
    reserveInterval? && reserveMinimum? && reserveMaximum?

  duration: ->
    parser = new TimeParser()
    parser.to_minutes $(@selector).val()


  hasMinimumRestriction: -> reserveMinimum > 0


  hasMaximumRestriction: -> reserveMaximum > 0


  isViolatingInterval: -> @duration() % reserveInterval != 0


  isExceedingMaximum: -> @hasMaximumRestriction() and @duration() > reserveMaximum


  isUnderMinimum: -> @hasMinimumRestriction() and @duration() < reserveMinimum


  hasError: -> @isViolatingInterval() or @isExceedingMaximum() or @isUnderMinimum()


  initAlert: -> $(@selector).after "<p id=\"#{@alertId}\" class=\"alert alert-danger hidden\"/>"


  setAlert: (msg)-> $("##{@alertId}").text msg


  currentErrorMessage: ->
    return "duration cannot exceed #{reserveMaximum} minutes" if @isExceedingMaximum()
    return "duration must be at least #{reserveMinimum} minutes" if @isUnderMinimum()
    return "duration must be a multiple of #{reserveInterval}" if @isViolatingInterval()


  showError: ->
    $(@selector).addClass 'interval-error'
    @setAlert @currentErrorMessage()
    $("##{@alertId}").removeClass 'hidden'


  hideError: ->
    $("##{@alertId}").addClass 'hidden'
    $(@selector).removeClass 'interval-error'


  respondToChange: ->
    $(@selector).keyup =>
      if @hasError()
        @showError()
      else
        @hideError()
