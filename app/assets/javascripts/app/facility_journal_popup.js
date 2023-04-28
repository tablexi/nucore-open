document.addEventListener("DOMContentLoaded", function() {
	const journalDateInput = document.querySelector("#journal_date");

	if (journalDateInput) {
		const submitDiv = document.querySelector(".submit");
		const earliestFulfilledAtDate = new Date(submitDiv.dataset.earliestFulfilledAt);

		submitDiv.addEventListener("click", function(event) {
			const journalDate = new Date(journalDateInput.value);

			const dateDiff = moment(journalDate).diff(earliestFulfilledAtDate, 'days');

			if (dateDiff >= 90) {
				event.preventDefault();
				$("#journal-date-popup").modal("show");
			}
		});
	}
});
