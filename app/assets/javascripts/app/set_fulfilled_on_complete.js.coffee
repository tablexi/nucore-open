class window.SetFulfilledOnComplete
  constructor: (@$fulfilled_at) ->
    return if @$fulfilled_at.data("complete-target-init")

    @$select = $(@$fulfilled_at.data("complete-target"))
    @initializeListener()
    @$select.change()
    @$fulfilled_at.data("complete-target-init", true)

  initializeListener: ->
    @$select.change (event) =>
      if $(event.target).find("option:selected").text() == "Complete"
        @$fulfilled_at.show()
      else
        @$fulfilled_at.hide()

  @activate: ->
    $(".js--showOnCompleteStatus").each (_, select) ->
      new SetFulfilledOnComplete($(select))

$ ->
  SetFulfilledOnComplete.activate()
  AjaxModal.on_show(SetFulfilledOnComplete.activate)
