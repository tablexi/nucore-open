(function($){
  $.fn.toggleSwitch = function(options) {
       
    var defaults = {
      duration: 400
    };
    settings = $.extend({}, defaults, options);

    this.each(function() {
      $this = $(this);
      $this.addClass("toggle_switch_checkbox");
      var newDiv = $("<div><div class=\"bg\"/><div class=\"switch\"/></div>").attr("id", "toggle_switch_" + $this.attr("id")).addClass("toggle_switch");
      this.toggle_switch = newDiv;
      newDiv.checkbox = $this;
      newDiv.click(function() { 
        newDiv.checkbox.trigger("click");
      });
      $this.after(newDiv);
      $this.bind("change", refreshToggle);
      // find the left of both on and off
      this.animation_properties = {
        off_left: this.toggle_switch.find(".switch").css("left"),
        on_left: this.toggle_switch.find(".switch").clone().addClass("toggle_on").css("left")
      }
    });

    function refreshToggle() {
      var newLeft = $(this).is(":checked") ? this.animation_properties.on_left : this.animation_properties.off_left;
      this.toggle_switch.find(".switch").stop().animate({left: newLeft }, settings.duration);
    }
  }
})(jQuery);
