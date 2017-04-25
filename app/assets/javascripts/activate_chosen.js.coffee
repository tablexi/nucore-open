class window.ChosenActivator
  @activate: ->
    $(".js--chosen").not(".optional").chosen()
    $(".js--chosen.optional").chosen(allow_single_deselect: true)

$ ->
  ChosenActivator.activate()

  AjaxModal.on_show ->
    # Give the browser just enough time to set the width of the select before
    # activating Chosen. Otherwise, it will sometimes appear as 0-width.
    setTimeout(ChosenActivator.activate, 25);

