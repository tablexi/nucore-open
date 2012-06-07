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
            content: tooltipContent
        });

        // Date select calendar
        $(".datepicker").datepicker({
          showOn: "button",
          buttonImage: "/images/icon-calendar.gif",
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
    
      });