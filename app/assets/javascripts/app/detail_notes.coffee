$ ->
  hiddenText = "More"
  openText = "Less"

  $('.js--toggleNote').on 'click', (e) ->
    e.preventDefault()
    $parent = $(this).parent()
    text = $(this).text()
    $parent.find(".js--note").toggle()
    $parent.find(".js--truncatedNote").toggle()
    $(this).text if text == hiddenText then openText else hiddenText
    return
