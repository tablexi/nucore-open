$(function() {
	$("select[multiple]").chosen();
	
	$(".datepicker").datepicker({maxDate: new Date()});
	// call trigger("change") to make sure that it updates on page load
	$(".datepicker[name=start_date]").change(DatePickerRange.updateEndMaxDate).trigger("change");
	$(".datepicker[name=end_date]").change(DatePickerRange.updateStartMinDate).trigger("change");
	
	
	
});

var DatePickerRange = {
	updateEndMaxDate: function() {
		var start = Date.parse($(this).val());
		$end = $(".datepicker[name=end_date]").datepicker("option", {minDate: start });
	},
	updateStartMinDate: function() {
		var end = Date.parse($(this).val());
		$start = $(".datepicker[name=start_date]").datepicker("option", {maxDate: end});
	}
		
}