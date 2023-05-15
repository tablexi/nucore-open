document.addEventListener("DOMContentLoaded", function() {
  $(function(){
    const dateData = document.querySelector("#js--journal-date-data");
    const today = dateData.dataset["today"];
    const earliestJournalDate = dateData.dataset["earliestJournalDate"];

    $("#journal_date").val(today).datepicker({
      "minDate": earliestJournalDate,
      "maxDate": today
    });
  });

  $(function(){
    $("#journals_create_form").submit(function(e) {
      $(e.target).find(":submit").attr("disabled", "true");
    });
  });

  const table = document.querySelector("table.js--transactions-table");
  const submitDiv = document.querySelector(".submit");
  let earliestFulfilledAtDate;
  
  table.addEventListener("click", setEarliestFulfilledAtDate);
  submitDiv.addEventListener("click", handleModals);
  
  function setEarliestFulfilledAtDate(event) {
    const dates = [];
    const checked = document.querySelectorAll("table.js--transactions-table tr td input[type='checkbox']:checked");
  
    checked.forEach(checkedBox => {
      const row = checkedBox.parentElement.parentElement;
      const date= new Date(row.querySelector(".js--date-field").innerHTML);
      dates.push(date);
    });

    dates.sort((a, b) => a.getTime() - b.getTime());
    earliestFulfilledAtDate = dates[0];
  }
  
  function handleModals(event) {
    const journalDateInput = document.querySelector("#journal_date");
    const journalDate = new Date(journalDateInput.value);
  
    const dateDiff = moment(journalDate).diff(earliestFulfilledAtDate, "days");
  
    if (dateDiff >= 90) {
      event.preventDefault();
      $("#journal-date-popup").modal("show");
    }
    else if ($("#journal-creation-reminder").length) {
      event.preventDefault();
      $("#journal-creation-reminder").modal("show");
    }
  }
});
