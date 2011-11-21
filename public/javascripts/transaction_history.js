$(function() {
	$("select[multiple]").chosen();
	
	$(".datepicker").datepicker({maxDate: new Date()});
	// call trigger("change") to make sure that it updates on page load
	$(".datepicker[name=start_date]").change(DatePickerRange.updateEndMaxDate);
	$(".datepicker[name=end_date]").change(DatePickerRange.updateStartMinDate);
	
	
	
});

var DatePickerRange = {
	updateEndMaxDate: function() {
		var start = Date.parse($(this).val());
		$(".datepicker[name=end_date]").datepicker("option", {minDate: start });
	},
	updateStartMinDate: function() {
		var end = Date.parse($(this).val());
		$(".datepicker[name=start_date]").datepicker("option", {maxDate: end});
	}
		
}