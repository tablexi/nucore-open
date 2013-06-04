$(function() {
  //Set Draggable Unit, grid and axis
	$( ".reschedulable .unit:not(.blackout)" ).draggable({
	  axis: "x",
	  containment: "parent",
	  grid: [ 2, 0],
	  opacity: 0.7,
	  revert: 'invalid',
	    stop: function(){
          $(this).draggable('option','revert','invalid');  
      }
	});
  //The unit container will fit the units. 
	$('.reschedulable .unit_container').droppable({
      tolerance: 'fit'
  });
  //Do not allow the overlap, yell at me if I try to drop a reservation on a reservation
  $('.reschedulable .unit').droppable({
    greedy: true,
    tolerance: 'touch',
    hoverClass: "invalid",
    drop: function(event,ui){
       $(this).off('invalid');
        ui.draggable.draggable('option','revert',true);
        alert("These Times Over Lap - You Can't Do that.");
    }
  })
  //Tool Tip
  tooltipContent = function($el, $tip) {
    var id = /block_reservation_(\d+)/.exec($el.attr("id"))[1];
    return $("#tooltip_reservation_" + id).html();
  }

  $('.tip').tooltipsy({
      content: tooltipContent,
      hide: function (e, $el) {
             $el.delay(500),
             $el.fadeOut(10)
         } 
  });

 /*  $(".tooltip_stay").mouseenter( function(){
      setTimeout( function(){
        $('.tooltip_stay').css('background','red');
      },1500);
   }); */


  // Date select calendar
  $(".datepicker").datepicker({
    showOn: "button",
    buttonImage: window.calendar_image_path,
    buttonImageOnly: true
  }).change(function() {
    $(this).parents("form").submit();
  });

  //Get the Current Hour, create a class and add it the time div
  time = function() {
    $e = $('.current_time');
    var currentTime = new Date();
    // minutes since midnight
    var minutes = currentTime.getHours() * 60 + currentTime.getMinutes();
    // Cache the pixel to minute ratio based on where it's initially displayed
    if (!window.PIXEL_TO_MINUTE_RATIO) {
      var pixels = parseInt($e.css('left'));
      window.PIXEL_TO_MINUTE_RATIO = (pixels / minutes).toFixed(2);
    }
    var pixels = Math.floor(minutes * PIXEL_TO_MINUTE_RATIO) + 'px'
    $e.css('left', pixels);
  };  
  time();
  setInterval(time, 30000);

  showOrHideCancelled = function() {
    if ($('#show_cancelled').is(':checked')) {
      $('.status_cancelled').fadeIn('fast');
    } else {
      $('.status_cancelled').fadeOut('fast');  
    }
    
  }
  $('#show_cancelled').change(showOrHideCancelled);
  // no animation when first loading
  $('.status_cancelled').toggle($('#show_cancelled').is(':checked'));
  

  $('.relay_checkbox :checkbox')
  .bind('click', function(e) {
    if (confirm("Are you sure you want to toggle the relay?")) {
      $(this).parent().addClass("loading");
      $.ajax({
        url: $(this).data("relay-url"),
        success: function(data) {
          updateRelayStatus(data.instrument_status);
        },
        data: {
          // This is what we're switching to, not what we currently display
          switch: $(this).is(":checked") ? 'off' : 'on'
        },
        dataType: 'json'
      });
    } else {
      return false;
    }
  })
  .toggleSwitch();

  function loadRelayStatuses() {
    $.ajax({
      url: '../instrument_statuses',
      success: function(data) {
        for(var i = 0; i < data.length; i++) {
          updateRelayStatus(data[i].instrument_status);
          
        }
        // Refresh 2 minutes after updating
        setTimeout(loadRelayStatuses, 120000);
      },
      dataType: 'json'
    });
  }    
  
  function updateRelayStatus(stat) {
    $checkbox = $("#relay_" + stat.instrument_id);
    // remove pre-existing errors
    $checkbox.parent().find("span.error").remove();
    if (stat.error_message) {
      $checkbox.prop("disabled", true);
      // add a new error if there is one
      $checkbox.parent().append($("<span class=\"error\" title=\"" + stat.error_message + "\"></span>"));
    } else {
      $checkbox.prop("disabled", false).prop("checked", stat.is_on);
    }
    $checkbox.parent().removeClass("loading");
    $checkbox.trigger("change");
  }

  $('.relay_checkbox').addClass('loading');
  // Only try to load relay statuses if there are relays to check
  if ($('.relay_checkbox :checkbox').length > 0) loadRelayStatuses();
});