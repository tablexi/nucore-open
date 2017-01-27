class window.MergeOrderForm
  constructor: (@$form) ->
    @$fulfilled_at = @$form.find("#fulfilled_at")
    @$order_status_id = @$form.find("#order_status_id")
    @initializeListener()
    @$order_status_id.change()

  initializeListener: ->
    @$order_status_id.change (event) =>
      if $(event.target).find("option:selected").text() == "Complete"
        @$fulfilled_at.show()
      else
        @$fulfilled_at.hide()

$ ->
  $(".js--edit-order").each (_, form) -> new MergeOrderForm($(form))
