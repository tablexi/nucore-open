/**
 * Toggle the display of expired accounts in the user accounts table
 */
window.addEventListener("DOMContentLoaded", () => {
	const toggleExpiredAcctsBtn = document.querySelector(".toggle_expired_accts_btn--js");
	const expiredAccts = document.querySelectorAll("tr.expired--js");
	let hideAccounts = false;

	if (toggleExpiredAcctsBtn) { toggleExpiredAcctsBtn.addEventListener("click", toggleExpiredAccounts); }

	function toggleExpiredAccounts() {
		hideAccounts = !hideAccounts;
		let displayStyle;
		let buttonText;

		if (hideAccounts) {
			displayStyle = "none";
			buttonText = "Show Expired Accounts";
		} else {
			displayStyle = "table-row";
			buttonText = "Hide Expired Accounts";
		}

		expiredAccts.forEach((acctEle) => {
			acctEle.style.display = displayStyle;
			toggleExpiredAcctsBtn.textContent = buttonText;
		});
	}

});
