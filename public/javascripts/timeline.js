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
        $(".datepicker").datepicker();

        //Get the Current Hour, create a class and add it the time div
        time = function() {
          var currentTime = new Date();
          var hours = currentTime.getHours();
          $('.current_time').addClass("hour_" + hours);
        };  
        time();
        setInterval(time, 500);
    
      });