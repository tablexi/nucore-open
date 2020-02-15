document.addEventListener("DOMContentLoaded", function() {
  function moveSelected(fromBox, toBox) {
    const selected = Array.from(fromBox.options).filter(function(option) { return option.selected });
    selected.forEach(function(option) {
      toBox.options.add(option);
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
    Array.from(select.selectedOptions).forEach(function(option) {
      const index = option.index;
      if (index > 0) {
        select.removeChild(option);
        select.add(option, index - 1);
      }
    });
  }

  function moveSelectedDown(select) {
     Array.from(select.selectedOptions).reverse().forEach(function(option) {
      const index = option.index;
      if (index < select.options.length) {
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
