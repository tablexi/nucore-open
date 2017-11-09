$ ->
  $("[data-disables]").on "change", ->
    attribute_id = $(@).data("disables")
    is_checked = $(@).is(":checked")
    $(attribute_id).find("input").prop("disabled", !is_checked)
    $(attribute_id).toggle(is_checked)

  .trigger("change")
