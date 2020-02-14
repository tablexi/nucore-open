document.addEventListener("DOMContentLoaded", function() {
  function sortChildren(node) {
    Array.from(node.children).sort(function(a, b) {
      return a.textContent.localeCompare(b.textContent, 'en', {'sensitivity': 'base'});
    }).forEach(function(element) {
      node.appendChild(element);
    })
  }

  document.querySelectorAll("[draggable=true]").forEach(function(element) {
    element.addEventListener("dragstart", function(e) {
      console.debug("dragstart", e.innerHTML);
      e.dataTransfer.setData('text/plain', this.dataset.dragId);
    });
  });

  document.querySelectorAll(".js--dropTarget").forEach(function(dropTarget) {
    dropTarget.addEventListener("dragover", function(e) {
      e.preventDefault();
    });

    dropTarget.addEventListener("drop", function(e) {
      const droppedNode = document.querySelector("[data-drag-id='" + e.dataTransfer.getData("text/plain") + "']");
      const dropTargetElement = this.querySelector(".js--dropTargetElement") || this;
      dropTargetElement.appendChild(droppedNode);
      sortChildren(dropTargetElement);
    });
  });
});
