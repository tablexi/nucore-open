$ ->
  hiddenText = "More"
  openText = "Less"

  $('.js--toggleNote').on 'click', (e) ->
    e.preventDefault()
    $parent = $(@).parent()
    text = $(@).text()
    $parent.find(".js--note").toggle()
    $parent.find(".js--truncatedNote").toggle()
    $(@).text if text == hiddenText then openText else hiddenText
    return
