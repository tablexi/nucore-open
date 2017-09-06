class window.MergeOrder
  constructor: (@$form) ->
    # empty body

  initTimeBasedServices: ->
    @$quantity_field = @$form.find(".js--edit-order__quantity")
    console.debug "quantity field", @$quantity_field
    @$timed_quantity_display_field = @$form.find(".js--edit-order__timed-quantity")
    console.debug "timed quantity field", @$timed_quantity_display_field
    # clockpunch converts the original field into a field with name _display.
    # We will need to disable both the visible display field and the hidden field
    # so they don't get sent as part of the POST.
    @$timed_quantity_display_field.timeinput()
    @$timed_quantity_hidden_field = @$timed_quantity_display_field.data("timeparser").$hidden_field

    @$form.find(".js--edit-order__product").on "change", (event) =>
      is_timed = $(event.target).find(":selected").data("timed-product")

      @$timed_quantity_display_field.toggle(is_timed)
      @$timed_quantity_display_field.prop("disabled", !is_timed)
      @$timed_quantity_hidden_field.prop("disabled", !is_timed)

      @$quantity_field.val(1) if is_timed
      @$quantity_field.prop("disabled", is_timed)

    @$form.find("#product_add").trigger("change")

$ ->
  new MergeOrder($(".js--edit-order")).initTimeBasedServices()
