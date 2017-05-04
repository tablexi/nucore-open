class window.ResponsiveTable

  @respond: ->
    return unless window.IS_RESPONSIVE
    $(".js--responsive_table").each (index, table) ->
      new ResponsiveTable($(table)).make_responsive()

  constructor: (@table) ->

  make_responsive: ->
    @fill_empty_cells()
    @add_responsive_headers()

  fill_empty_cells: ->
    @table.find("td").each (index, cell) =>
      empty = $(cell).text().trim().length == 0
      $(cell).append("&nbsp;") if empty

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
