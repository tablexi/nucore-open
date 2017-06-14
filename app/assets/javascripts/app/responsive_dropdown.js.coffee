# Fixes an issue where the navigation dropdown in bootstrap does not
# work in mobile safari
# https://stackoverflow.com/questions/17178606/bootstrap-v2-dropdown-navigation-not-working-on-mobile-browsers
#
#

$ ->
  $("li.dropdown a").click (e) =>
    e.stopPropagation()
    $(e.target).next('ul.dropdown-menu').css("display", "block")
