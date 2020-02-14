document.addEventListener("DOMContentLoaded", function() {
  function caseInsensitiveCompare(a, b) {
    return a.textContent.localeCompare(b.textContent, 'en', {'sensitivity': 'base'});
  }

  function sortChildrenNodes(parent, sortBy) {
    Array.from(parent.children).sort(sortBy).forEach(function(element) {
      parent.appendChild(element);
    })
  }

  document.querySelectorAll("[draggable=true]").forEach(function(element) {
    element.addEventListener("dragstart", function(e) {
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
      sortChildrenNodes(dropTargetElement, caseInsensitiveCompare);
    });
  });
});
