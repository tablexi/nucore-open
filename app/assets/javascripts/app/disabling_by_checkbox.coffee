$ ->
  $("[data-disables]").on "change", ->
    attribute_id = $(this).data("disables")
    is_checked = $(this).is(":checked")
    $(attribute_id).find("input").prop("disabled", !is_checked)
    $(attribute_id).toggle(is_checked)

  .trigger("change")
