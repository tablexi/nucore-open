class window.ChosenActivator
  @activate: ->
    $(".js--chosen").not(".optional").chosen()
    $(".js--chosen.optional").chosen(allow_single_deselect: true)

$ ->
  ChosenActivator.activate()
  AjaxModal.on_show(ChosenActivator.activate)

