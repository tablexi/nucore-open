// On bundle_products#new, switch between a regular quantity field and a time
// quantity field based on the type of product selected.
$(function() {
  $productSelect = $(".js--bundleProducts__productSelect");

  if ($productSelect.length) {
    var timeQuantityTypes = $productSelect.data("timed-quantity-types").split(", ")
    var $quantityField = $(".js--bundleProducts__quantityField");
    var $timedQuantityField = $(".js--bundleProducts__timedQuantityField");

    $productSelect.bind("change", function(evt) {
      var selectedType = $(evt.target).find(":selected").closest("optgroup").attr("label");
      var isTimeSelected = timeQuantityTypes.includes(selectedType);

      // Show/hide and Enable/Disable the regular quantity vs time quantit fields
      $quantityField.toggle(!isTimeSelected).find("input").prop("disabled", isTimeSelected);
      $timedQuantityField.toggle(isTimeSelected).find("input").prop("disabled", !isTimeSelected);
    }).trigger("change");

    // Keep the two fields synchronized. In the time input field, there is a visible
    // field, which is the formatted (H:MM) version and the hidden is a raw quantity.
    $quantityField.on("change", function(evt) {
      $timedQuantityField.find("input[type=hidden]").val($(evt.target).val()).trigger("change");
    });

    $timedQuantityField.on("change", "input[type=hidden]", function(evt) {
      $quantityField.find("input").val($(evt.target).val())
    });
  }
});
