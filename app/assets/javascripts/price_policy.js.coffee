$(document).ready ->
  $ ->
    $("#start_datepicker").datepicker minDate: null
    $("#expire_datepicker").datepicker minDate: null

  $interval = $("#interval")

  $interval.change ->
    int_value = $(this).val()
    interval = "#{int_value} minute"
    interval += "s" if int_value > 1
    $("span.interval_replace").each -> $(this).html(interval)

  $interval.trigger('change')

  isFiniteAndPositive = (number)-> isFinite(number) && number > 0

  toggleGroupFields = ($checkbox)->
    $cells = $checkbox.parents("tr").find("td")
    isDisabled = !$checkbox.prop "checked"
    $cells.toggleClass "disabled", isDisabled
    $cells.find("input[type=text], input[type=hidden]").each ->
      # If we're hiding the value, store it so we can retreive it later
      $inputElement = $(this)
      $inputElement.data "original-value", $inputElement.val() if $inputElement.val()
      $inputElement.val(if isDisabled then "" else $inputElement.data("original-value"))
      $inputElement.prop "disabled", isDisabled

  deriveAdjustedCost = (unadjustedCost, usageSubsidyString)->
    usageSubsidy = parseFloat usageSubsidyString
    if isFiniteAndPositive(usageSubsidy)
      (unadjustedCost * (1.0 - usageSubsidy)).toFixed 2
    else
      unadjustedCost

  getMasterUsageRate = ->
    rate = parseFloat $("input.master_usage_cost.usage_rate").val()
    if isFiniteAndPositive(rate) then rate else 0

  getUsageAdjustment = (usageAdjustmentElement)->
    usageAdjustment = parseFloat usageAdjustmentElement.value
    if isFiniteAndPositive(usageAdjustment) then usageAdjustment else 0

  setUsageSubsidy = (usageAdjustmentElement, usageSubsidy)->
    $(usageAdjustmentElement).parents("tr").find("span.minimum_cost").data("usageSubsidy", usageSubsidy)

  refreshCosts = ->
    $(".master_minimum_cost").each (index, element)-> setInternalCost element
    $("input[type=hidden].usage_cost").val(getMasterUsageRate())

  updateUsageSubsidy = (usageAdjustmentElement)->
    usageAdjustment = getUsageAdjustment usageAdjustmentElement
    usageRate = getMasterUsageRate()
    setUsageSubsidy usageAdjustmentElement,
      if usageAdjustment > 0 && usageRate > 0
        usageAdjustment / usageRate
      else
        0
    refreshCosts()

  setInternalCost = (o)->
    if o.className.match /master_(\S+_cost)/
      desiredClass = RegExp.$1
      $("span.#{desiredClass}").each ->
        $costElement = $(this)
        cost = deriveAdjustedCost(o.value, $costElement.data("usageSubsidy"))
        $costElement.html(cost)
        $costElement.siblings("input[type=hidden].#{desiredClass}").val(cost)

  $(".can_purchase").change(->
    toggleGroupFields $(this)
  ).trigger("change")

  $("input[type=text]").keyup(->
    setInternalCost this
    $(".usage_adjustment").each -> updateUsageSubsidy(this)
  ).trigger("keyup")
