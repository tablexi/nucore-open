$(document).ready ->

  isFiniteAndPositive = (number) -> isFinite(number) && number > 0

  hardToggleField = ($inputElement, isDisabled) ->
    # If we're hiding the value, store it so we can retreive it later
    $inputElement.data "original-value", $inputElement.val() if $inputElement.val()
    $inputElement.val(if isDisabled then "" else $inputElement.data("original-value"))
    $inputElement.prop "disabled", isDisabled

  toggleGroupFields = ($checkbox) ->
    $cells = $checkbox.parents("tr").find("td")
    isDisabled = !$checkbox.prop "checked"
    $cells.toggleClass "disabled", isDisabled
    $cells.find("input[type=text], input[type=hidden], input[type=checkbox]").not($checkbox).each (_i, elem) ->
      hardToggleField($(elem), isDisabled)
    # If we are enabling the row, make sure the cancellation cost field gets the correct state
    $cells.find(".js--full_cancellation_cost").trigger("change") unless isDisabled

  getMasterUsageRate = ->
    rate = parseFloat $("input.master_usage_cost.usage_rate").val()
    if isFiniteAndPositive(rate) then rate else 0

  getUsageAdjustment = (usageAdjustmentElement) ->
    usageAdjustment = parseFloat usageAdjustmentElement.value
    if isFiniteAndPositive(usageAdjustment) then usageAdjustment else 0

  setUsageSubsidy = (usageAdjustmentElement, usageSubsidy) ->
    $(usageAdjustmentElement).parents("tr").find("span.minimum_cost").data("usageSubsidy", usageSubsidy)

  refreshCosts = ->
    $(".master_minimum_cost").each (index, element) -> setInternalCost element
    $("input[type=hidden].usage_cost").val(getMasterUsageRate())

  updateUsageSubsidy = (usageAdjustmentElement) ->
    usageAdjustment = getUsageAdjustment usageAdjustmentElement
    usageRate = getMasterUsageRate()
    setUsageSubsidy usageAdjustmentElement,
      if usageAdjustment > 0 && usageRate > 0
        usageAdjustment / usageRate
      else
        0
    refreshCosts()

  toggleFullCancellationCost = ($checkbox) ->
    isChecked = $checkbox.prop "checked"
    $inputElement = $checkbox.parents(".js--full_cancellation_cost_container").find("input[type=text]")
    hardToggleField($inputElement, isChecked)

  setInternalCost = (o) ->
    if o.className.match /master_(\S+_cost)/
      desiredClass = RegExp.$1
      $("span.#{desiredClass}").each (i, elem) ->
        $costElement = $(elem)
        $costElement.html(o.value)
        $costElement.siblings("input[type=hidden].#{desiredClass}").val(o.value)


  $(".js--full_cancellation_cost").change((evt) ->
    toggleFullCancellationCost($(evt.target))
  ).trigger("change")

  $(".can_purchase").change((evt) ->
    toggleGroupFields $(evt.target)
  ).trigger("change")

  $("input[type=text]").keyup((evt) ->
    setInternalCost evt.target
    $(".usage_adjustment").each (adjustment_elem) -> updateUsageSubsidy(adjustment_elem)
  ).trigger("keyup")
