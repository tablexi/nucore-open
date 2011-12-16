$(function() {
	$("select[multiple]").chosen();
	
	$(".datepicker").datepicker({maxDate: new Date()});
	// call trigger("change") to make sure that it updates on page load
	$(".datepicker[name=start_date]").change(DatePickerRange.updateEndMaxDate).trigger("change");
	$(".datepicker[name=end_date]").change(DatePickerRange.updateStartMinDate).trigger("change");
	
	
	
});

var DatePickerRange = {
	updateEndMaxDate: function() {
		$val = $(this).val();
		if ($val) {
			var start = Date.parse($val);
			$(".datepicker[name=end_date]").datepicker("option", {minDate: start });
		}
	},
	updateStartMinDate: function() {
		$val = $(this).val();
		if ($val) {
			var end = Date.parse($val);
			$(".datepicker[name=start_date]").datepicker("option", {maxDate: end});
		}
	}
		
}