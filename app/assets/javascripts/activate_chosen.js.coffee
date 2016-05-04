$ ->
  $(".js--chosen").not(".optional").chosen()
  $(".js--chosen.optional").chosen(allow_single_deselect: true)
