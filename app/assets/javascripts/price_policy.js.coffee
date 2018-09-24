$(document).ready ->

  isFiniteAndPositive = (number) -> isFinite(number) && number > 0

  # In addition to disabling the field, also hide its value. But still store it
  # so we can display it again if it gets renabled
  hardToggleField = ($inputElement, isDisabled) ->
    $inputElement.data "original-value", $inputElement.val() if $inputElement.val()
    $inputElement.val(if isDisabled then "" else $inputElement.data("original-value"))
    $inputElement.prop "disabled", isDisabled

  # Triggered by "Can purchase?"
  toggleFieldsInSameRow = ($checkbox) ->
    $cells = $checkbox.parents("tr").find("td")
    isDisabled = !$checkbox.prop "checked"
    $cells.toggleClass "disabled", isDisabled
    $cells.find("input[type=text], input[type=hidden], input[type=checkbox]").not($checkbox).each (_i, elem) ->
      hardToggleField($(elem), isDisabled)
    # If we are enabling the row, make sure the cancellation cost field gets the correct state
    $cells.find(".js--fullCancellationCost").trigger("change") unless isDisabled

  updateAdjustmentFields = ($sourceElement) ->
    rate = parseFloat($sourceElement.val())
    rate = if isFiniteAndPositive(rate) then rate else 0

    $targets = $(".js--adjustmentRow").find($sourceElement.data("target"))
    $targets.filter(":input").val(rate)
    $targets.filter("span").html(rate)

  toggleFullCancellationCostInCurrentCell = ($checkbox) ->
    $container = $checkbox.parents(".js--cancellationCostContainer")
    hardToggleField($container.find("input[type=text]"), $checkbox.is(":checked"))

  toggleFullCancellationInAdjustmentRows = (isChecked) ->
    $adjustmentFields = $(".js--adjustmentRow .js--fullCancellationCost")
    $adjustmentFields.val(if isChecked then "1" else "0")
    hardToggleField($adjustmentFields.siblings(".js--cancellationCost").filter(":input"), isChecked)
    # Show/hide the pricing spans
    $adjustmentFields.siblings(".js--cancellationCost").filter("span").toggle(!isChecked)

  $(".js--canPurchase").change((evt) ->
    toggleFieldsInSameRow $(evt.target)
  ).trigger("change")

  $(".js--fullCancellationCost").change((evt) ->
    $elem = $(evt.target)
    toggleFullCancellationCostInCurrentCell($elem)
    if $elem.parents(".js--masterInternalRow").length
      toggleFullCancellationInAdjustmentRows($elem.is(":checked"))
      # Update trigger the adjustment rows to be updated off of the value
      $elem.parents(".js--cancellationCostContainer").find(".js--cancellationCost")
        .trigger("keyup") unless $elem.is(":checked")
  ).trigger("change")

  $(".js--masterInternalRow input[type=text]").keyup((evt) ->
    updateAdjustmentFields($(evt.target))
  ).trigger("keyup")
