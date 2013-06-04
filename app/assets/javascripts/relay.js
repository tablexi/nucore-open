$(document).ready(function() {
  $(".instrument_table").click(function(e){
    var link = $(e.target);
    if (!link.hasClass('instrument_status_link') && !link.hasClass('instrument_switch_link')) {
      return;
    }
	e.preventDefault();
    var inst_id = link.attr("id").match(/\d+/)
    var status_div = $('#instrument_status_' + inst_id);
    old_html = status_div.html();
    status_div.html('Updating. Please Wait.');
    jQuery.ajax({
      type:    "get",
      url:     link.attr("href"),
      timeout: 10000,
      success: function(r){
		status_div.html(r);
      },
      error: function(){
		status_div.html(old_html);
      }
	});
    return false;
  });
});