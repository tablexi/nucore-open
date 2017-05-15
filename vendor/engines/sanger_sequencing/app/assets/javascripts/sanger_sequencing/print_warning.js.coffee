# Per https://www.tjvantoll.com/2012/06/15/detecting-print-requests-with-javascript/

class @PrintWarning

  initListener: ->
    return unless @shouldWarn()
    @listen()
    window.onbeforeprint = @onPrintAction

  shouldWarn: -> $(".js--print-warning").length

  listen: ->
    @mediaQuery().addListener (query) =>
      return unless query.matches
      @onPrintAction()

  mediaQuery: -> window.matchMedia("print")

  onPrintAction: ->
    alert("This order is not submitted.
      Please click Save Submission and move to the next step before
      printing your sample sheet.")

$ ->
  new PrintWarning().initListener()
