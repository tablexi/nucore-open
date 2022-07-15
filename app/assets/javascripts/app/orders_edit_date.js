window.addEventListener("DOMContentLoaded", function() {
  const orderStatusSelect = document.querySelector("#order_status_id");
  
  // In the _edit_date partial, show the "Fulfilled at" field only if 
  // the "Order Status" is "Complete"
  if (orderStatusSelect) {
    const fulfilledAt = document.querySelector(".backdate_fulfilled_at");
    let displayStyle = "none";
  
    fulfilledAt.style.display = displayStyle;
  
    orderStatusSelect.addEventListener("change", function() {
      const selectedValue = orderStatusSelect.value;
  
      // "Complete" is the 4th item in the dropdown
      if (selectedValue === "4") {
        displayStyle = "";
      }
      else {
        displayStyle = "none";
      }
  
      fulfilledAt.style.display = displayStyle;
    });
  }
});
