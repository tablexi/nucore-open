$(document).ready ->

  # Select all for checkboxes
  selectAllSelector = $("a#selectAllClone")
  $(selectAllSelector).on "click", ->
    checkboxes = $(".clone-checkbox")
    if checkboxes.prop("checked")
      checkboxes.prop "checked", false
      selectAllSelector.html("Select All")
    else
      checkboxes.prop "checked", true
      selectAllSelector.html("Deselect All")

  # Prevent empty form submission
  $('#cloneAccountForm').submit ->
    if $(this).find('input:checked').length == 0
      false
