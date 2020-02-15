document.addEventListener("DOMContentLoaded", function() {
  function moveSelected(fromSelect, toSelect) {
    const selected = Array.from(fromSelect.options).filter(function(option) { return option.selected });
    selected.forEach(function(option) {
      toSelect.options.add(option);
      option.selected = false;
    })
  }

  function clearSelected(select) {
    Array.from(select.options).forEach(function(option) { option.selected = false });
  }

  function selectAll(select) {
    Array.from(select.options).forEach(function(option) { option.selected = true });
  }

  function removeUnselected(included) {
    Array.from(included.options).forEach(function(option) {
      if (!option.selected) {
        option.remove();
      }
    });
  }

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

  Array.from(document.getElementsByClassName("js--moveBetweenSelects")).forEach(function(parent) {
    const includedSelect = parent.querySelector(".js--included");
    const excludedSelect = parent.querySelector(".js--excluded");

    // The included select box should start with ALL the possible values included
    // and have the actual included values selected. This way, the page would still
    // work without Javascript.
    removeUnselected(includedSelect);
    clearSelected(includedSelect);
    clearSelected(excludedSelect);

    parent.querySelector(".js--include").addEventListener("click", function(evt) {
      evt.preventDefault();
      moveSelected(excludedSelect, includedSelect);
    });

    parent.querySelector(".js--exclude").addEventListener("click", function(evt) {
      evt.preventDefault();
      moveSelected(includedSelect, excludedSelect);
    })

    parent.querySelector(".js--moveUp").addEventListener("click", function(evt) {
      evt.preventDefault();
      moveSelectedUp(includedSelect);
    });

    parent.querySelector(".js--moveDown").addEventListener("click", function(evt) {
      evt.preventDefault();
      moveSelectedDown(includedSelect);
    });

    parent.closest("form").addEventListener("submit", function(evt) {
      evt.preventDefault();
      selectAll(includedSelect);
      excludedSelect.disabled = true;
      evt.target.submit();
    });
  });
});
