class window.MergeOrder
  constructor: (@$form) ->
    # empty body

  initTimeBasedServices: ->
    return unless @$form.length

    @$quantity_field = @$form.find(".js--edit-order__quantity")
    @$duration_display_field = @$form.find(".js--edit-order__duration")

    # clockpunch converts the original field into a field with name _display.
    # We will need to disable both the visible display field and the hidden field
    # so they don't get sent as part of the POST unless a timed service is
    # selected.
    @$duration_display_field.timeinput()
    @$duration_hidden_field = @$duration_display_field.data("timeparser").$hidden_field

    @$form.find(".js--edit-order__product").on "change", (event) =>
      is_timed = $(event.target).find(":selected").data("timed-product")

      @$duration_display_field.toggle(is_timed)
      @$duration_display_field.prop("disabled", !is_timed)
      @$duration_hidden_field.prop("disabled", !is_timed)

      @$quantity_field.val(1) if is_timed
      @$quantity_field.prop("disabled", is_timed)

    @$form.find(".js--edit-order__product").trigger("change")

$ ->
  new MergeOrder($(".js--edit-order")).initTimeBasedServices()
