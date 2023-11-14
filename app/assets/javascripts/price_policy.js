/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
$(document).ready(function() {

  const isFiniteAndPositive = number => isFinite(number) && (number > 0);

  // In addition to disabling the field, also hide its value. But still store it
  // so we can display it again if it gets renabled
  const hardToggleField = function($inputElement, isDisabled) {
    if ($inputElement.val()) { $inputElement.data("original-value", $inputElement.val()); }
    $inputElement.val(isDisabled ? "" : $inputElement.data("original-value"));
    return $inputElement.prop("disabled", isDisabled);
  };

  // Triggered by "Can purchase?"
  const toggleFieldsInSameRow = function($checkbox) {
    const $cells = $checkbox.parents("tr").find("td");
    const isDisabled = !$checkbox.prop("checked");
    $cells.toggleClass("disabled", isDisabled);
    $cells.find("input[type=text], input[type=hidden], input[type=checkbox]").not($checkbox).each((_i, elem) => hardToggleField($(elem), isDisabled));
    // If we are enabling the row, make sure the cancellation cost field gets the correct state
    if (!isDisabled) { return $cells.find(".js--fullCancellationCost").trigger("change"); }
  };

  const updateAdjustmentFields = function($sourceElement) {
    let rate = parseFloat($sourceElement.val());
    rate = isFiniteAndPositive(rate) ? rate : 0;

    const $targets = $(".js--adjustmentRow").find($sourceElement.data("target"));
    $targets.filter(":input").val(rate);
    return $targets.filter("span").html(rate);
  };

  const toggleFullCancellationCostInCurrentCell = function($checkbox) {
    const $container = $checkbox.parents(".js--cancellationCostContainer");
    return hardToggleField($container.find("input[type=text]"), $checkbox.is(":checked"));
  };

  const toggleFullCancellationInAdjustmentRows = function(isChecked) {
    const $adjustmentFields = $(".js--adjustmentRow .js--fullCancellationCost");
    $adjustmentFields.val(isChecked ? "1" : "0");
    hardToggleField($adjustmentFields.siblings(".js--cancellationCost").filter(":input"), isChecked);
    // Show/hide the pricing spans
    return $adjustmentFields.siblings(".js--cancellationCost").filter("span").toggle(!isChecked);
  };

  $(".js--canPurchase").change(evt => toggleFieldsInSameRow($(evt.target))).trigger("change");

  $(".js--fullCancellationCost").change(function(evt) {
    const $elem = $(evt.target);
    toggleFullCancellationCostInCurrentCell($elem);
    if ($elem.parents(".js--masterInternalRow").length) {
      toggleFullCancellationInAdjustmentRows($elem.is(":checked"));
      // Update trigger the adjustment rows to be updated off of the value
      if (!$elem.is(":checked")) { return $elem.parents(".js--cancellationCostContainer").find(".js--cancellationCost").trigger("keyup"); }
    }
  }).trigger("change");

  $(".js--masterInternalRow input[type=text]").keyup(evt => updateAdjustmentFields($(evt.target))).trigger("keyup");

  $(".js--price-policy-note-select").on("change", function(event) {
    const selectedOption = event.target.options[event.target.selectedIndex];
    const noteTextField = $(".js--price-policy-note");
    if (selectedOption.value === "Other") {
      return noteTextField.attr("hidden", false).val("");
    } else {
      noteTextField.attr("hidden", true);
      return noteTextField.val(selectedOption.value);
    }
  });

  $(".js--minDuration").on("change", function (event) {
    const columnIndex = event.target.dataset.index;
    const minDuration = event.target.value;
    $(`input[name*='duration_rates_attributes][${columnIndex}][min_duration_hours]']`).val(minDuration);
  });
});
