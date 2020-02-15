document.addEventListener("DOMContentLoaded", function() {
  function moveSelectedUp(select) {
    // Prevent movement if all the selected are at the beginning
    const firstOpenIndex = Array.from(select.options).find(function(option) { return !option.selected }).index;
    Array.from(select.selectedOptions).forEach(function(option) {
      const index = option.index;
      if (index > 0 && index > firstOpenIndex) {
        select.removeChild(option);
        lastIndex = index - 1;
        select.add(option, index - 1);
      }
    });
  }

  function moveSelectedDown(select) {
    // Prevent movement if all the selected are at the end
    const lastOpenIndex = Array.from(select.options).reverse().find(function(option) { return !option.selected }).index;
     Array.from(select.selectedOptions).reverse().forEach(function(option) {
      const index = option.index;
      if (index < select.options.length && index < lastOpenIndex) {
        select.removeChild(option);
        select.add(option, index + 1);
      }
    });
  }

  document.querySelectorAll(".js--multiSelectReorder__moveUp").forEach(function(button) {
    button.addEventListener("click", function(evt) {
      evt.preventDefault();
      moveSelectedUp(document.querySelector(button.dataset.target));
    });
  });

  document.querySelectorAll(".js--multiSelectReorder__moveDown").forEach(function(button) {
    button.addEventListener("click",  function(evt) {
      evt.preventDefault();
      moveSelectedDown(document.querySelector(button.dataset.target));
    });
  });
});
