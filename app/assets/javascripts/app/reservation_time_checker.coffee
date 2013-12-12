class window.ReservationTimeChecker
  constructor: (@selector, @alertId = 'duration-alert')->
    @initAlert()
    @respondToChange()


  duration: ->
    parser = new TimeParser()
    parser.to_minutes $(@selector).val()


  isViolatingInterval: -> @duration() % reserveInterval != 0


  isExceedingMaximum: -> @duration() > reserveMaximum


  isUnderMinimum: -> @duration() < reserveMinimum


  hasError: -> @isViolatingInterval() || @isExceedingMaximum() || @isUnderMinimum()


  initAlert: -> $(@selector).after "<p id=\"#{@alertId}\" class=\"alert alert-danger hidden\"/>"


  setAlert: (msg)-> $("##{@alertId}").text msg


  currentErrorMessage: ->
    return "duration cannot exceed #{reserveMaximum} minutes" if @isExceedingMaximum()
    return "duration must be at least #{reserveMinimum} minutes" if @isUnderMinimum()
    return "duration must be a multiple of #{reserveInterval}" if @isViolatingInterval()


  showError: ->
    $(@selector).css 'color', 'red'
    @setAlert @currentErrorMessage()
    $("##{@alertId}").removeClass 'hidden'


  hideError: ->
    $("##{@alertId}").addClass 'hidden'
    $(@selector).css 'color', 'black'


  respondToChange: ->
    $(@selector).keyup =>
      if @hasError()
        @showError()
      else
        @hideError()
