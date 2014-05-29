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

  if $interval.length > 0
    int_value = $interval.val()
    interval = "#{int_value} minute"
    interval += "s" if int_value > 1
    $("span.interval_replace").each -> $(this).html(interval)

  toggleGroupFields = ($checkbox)->
    $cells = $checkbox.parents("tr").find("td")
    isDisabled = !$checkbox.prop "checked"
    $cells.toggleClass "disabled", isDisabled
    $cells.find("input[type=text], input[type=hidden]").each ->
      # If we're hiding the value, store it so we can retreive it later
      $inputElement = $(this)
      if $inputElement.val()
        $inputElement.data "original-value", $inputElement.val()
      if isDisabled
        $inputElement.val ""
      else
        $inputElement.val $inputElement.data("original-value")
      $inputElement.prop "disabled", isDisabled

  deriveAdjustedCost = (unadjustedCost, usageSubsidyString)->
    usageSubsidy = parseFloat usageSubsidyString
    if isFinite usageSubsidy
      (unadjustedCost * (1.0 - usageSubsidy)).toFixed 2
    else
      unadjustedCost

  getMasterUsageRate = ->
    parseFloat $("input.master_usage_cost.usage_rate").val()

  setUsageSubsidy = (usageAdjustmentElement, usageSubsidy)->
    $(usageAdjustmentElement).parents("tr").find("span.minimum_cost").data("usageSubsidy", usageSubsidy.toFixed(2))

  refreshCosts = ->
    $(".master_minimum_cost").each (index, element)-> setInternalCost element

  updateUsageSubsidy = (usageAdjustmentElement)->
    usageAdjustment = parseFloat usageAdjustmentElement.value
    if isFinite usageAdjustment
      usageRate = getMasterUsageRate()
      if isFinite usageRate
        usageSubsidy = usageAdjustment / usageRate
        if isFinite usageSubsidy
          setUsageSubsidy usageAdjustmentElement, usageSubsidy
          refreshCosts()

  setInternalCost = (o)->
    if o.className.match /master_(\S+_cost)/
      desiredClass = RegExp.$1
      $spanElements = $("span.#{desiredClass}")
      cost = deriveAdjustedCost o.value, $spanElements.data("usageSubsidy")
      $spanElements.html cost
      $("input[type=hidden].#{desiredClass}").val cost

  $(".can_purchase").change(->
    toggleGroupFields $(this)
  ).trigger("change")

  $("input[type=text]").change(->
    setInternalCost this
    $(".usage_adjustment").each -> updateUsageSubsidy(this)
  ).trigger("change").keyup(-> setInternalCost(this))
