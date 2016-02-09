exports = exports ? this

class exports.Flash
  @notice: (message, location_selector = '#js--flash') ->
    @flash('notice', message, location_selector)

  @error: (message, location_selector = '#js--flash') ->
    @flash('error', message, location_selector)

  @info: (message, location_selector = '#js--flash') =>
    @flash('info', message, location_selector)

  @flash: (level, message, location_selector = '#js--flash') ->
    new Flash(location_selector).flash(level, message)

  constructor: (location_selector) ->
    @location_selector = $(location_selector)

  flash: (level, message) ->
    # existing flashes
    @location_selector.find(".alert").remove()

    flash = $("<p></p>").text(message).addClass('alert').addClass("alert-#{level}")
    @location_selector.append(flash)

    setTimeout ->
      flash.fadeOut('slow').remove()
    , 10000
