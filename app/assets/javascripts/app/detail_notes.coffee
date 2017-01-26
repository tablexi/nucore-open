$ ->
  hiddenText = "See Note"
  openText = "Hide Note"

  $('.js--toggleNote').on 'click', (e) ->
    e.preventDefault()
    $(this).next(".js--note").toggle()
    text = $(this).text()
    $(this).text if text == hiddenText then openText else hiddenText
    return
