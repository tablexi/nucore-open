window.addEventListener("DOMContentLoaded", () => {
  const orderStatusSelect = document.querySelector("#order_status_id");

  if (orderStatusSelect) {
    toggleFulfilledAt();
  
    orderStatusSelect.addEventListener("change", () => toggleFulfilledAt());

    // In the _edit_date partial, show the "Fulfilled at" field only if 
    // the "Order Status" is "Complete"
	  function toggleFulfilledAt() {
    	const fulfilledAt = document.querySelector(".backdate_fulfilled_at");
      let selectedValue = orderStatusSelect.value;
		  let displayStyle;

      // "Complete" is the 4th item in the dropdown
      if (selectedValue === "4") {
        displayStyle = "";
      }
      else {
        displayStyle = "none";
      }
  
      fulfilledAt.style.display = displayStyle;
	  }
  }
});
