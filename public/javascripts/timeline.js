$(function() {
    	  //Set Draggable Unit, grid and axis
    		// $( ".unit" ).draggable({
    		//   axis: "x",
    		//   containment: "parent",
    		//   grid: [ 2, 0],
    		//   opacity: 0.7,
    		//   revert: 'invalid',
    		//     stop: function(){
      //           $(this).draggable('option','revert','invalid');  
      //       }
    		// });
    	 //  //The unit container will fit the units. 
      // 	$('.unit_container').droppable({
      //       tolerance: 'fit'
      //   });
      //   //Do not allow the overlap, yell at me if I try to drop a reservation on a reservation
      //   $('.unit').droppable({
      //     greedy: true,
      //     tolerance: 'touch',
      //     hoverClass: "invalid",
      //     drop: function(event,ui){
      //        $(this).off('invalid');
      //         ui.draggable.draggable('option','revert',true);
      //         alert("These Times Over Lap - You Can't Do that.");
      //     }
      //   })
        //Tool Tip
        tooltipContent = function($el, $tip) {
          var result = '<strong>' + $el.data('user') + '</strong>';
          result += '<br />';
          result += '<small>' + $el.data('start') + "&ndash;" + $el.data('end') + "<br/>";
          if ($el.data('startable')) { result += '<a href="#">Begin</a>'; }
          if ($el.data('endable')) { result += '<a href="#">End</a>'; }
          //result += 
          //+ "<strong>Status</strong><br /><a href="#">Action Links</a>
          result += '</small>';
          return result;
        }
        $('.tip').tooltipsy({
            content: tooltipContent,
            css: {
              'padding': '5px',
              'max-width': '200px',
              'color': '#303030',
              'background-color': '#fff',
              'border': '1px solid #ccc',
              'border-radius' : '5px',
              '-moz-box-shadow': '0 0 10px rgba(0, 0, 0, .5)',
              '-webkit-box-shadow': '0 0 10px rgba(0, 0, 0, .5)',
              'box-shadow': '0 0 10px rgba(0, 0, 0, .5)',
              'text-shadow': 'none'
            }
        });
        //Get the Current Hour, create a class and add it the time div
        time = function() {
          var currentTime = new Date()
          var hours = currentTime.getHours()            
          $('.time').addClass("hour_" + hours);
        };  
        time();
        setInterval(time, 500);
    
      });