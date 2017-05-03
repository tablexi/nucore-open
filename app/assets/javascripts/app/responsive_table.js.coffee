class window.ResponsiveTable

  @respond: ->
    return unless window.IS_RESPONSIVE
    $(".js--responsive_table").each (index, table) ->
      new ResponsiveTable($(table)).add_responsive_headers()

  constructor: (@table) ->

  add_responsive_headers: ->
    @table.find("tbody tr").each (index, row) => @add_header_to_row($(row))

  add_header_to_row: ($row) ->
    $row.find("td").prepend (index) => @responsive_header(index)

  responsive_header: (index) ->
    $("<div>").addClass("responsive-header").text(@text_for_header(index))

  text_for_header: (index) =>
    header = $(@table.find("thead th").eq(index))
    header.data("mobile-header") || header.text()

$ ->
  ResponsiveTable.respond()
