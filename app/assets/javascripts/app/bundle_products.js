// On bundle_products#new, switch between a regular quantity field and a time
// quantity field based on the type of product selected.
$(function() {
  $productSelect = $(".js--bundleProducts__productSelect");
  const hints = document.querySelectorAll('.hint');

  hideElements(hints);

  if ($productSelect.length) {

    $productSelect.bind("change", function(evt) {
      hideElements(hints);

      let selectedType = $(evt.target).find(":selected").closest("optgroup").attr("label");

      if (selectedType) {
        let className = ".js--" + capitalizedToCamelCase(selectedType);
        document.querySelector(className).hidden = false;
      }

    }).trigger("change");

  }

  function capitalizedToCamelCase(str) {
    return (str[0].toLowerCase() + str.slice(1)).replaceAll(" ", "");
  }

  function hideElements(elements) {
    elements.forEach(function(element) {
      element.hidden = true;
    });
  }
});
