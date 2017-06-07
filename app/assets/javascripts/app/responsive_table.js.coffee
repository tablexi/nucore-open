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
    # Only get the immediate child cells of the row. Without the `>`, it could
    # also find cells in nested tables.
    cells = $row.find("> td")
    cells.prepend (index) => @responsive_header($row, index)

  responsive_header: ($row, index) ->
    $("<div>").addClass("responsive-header").text(@text_for_header($row, index))

  text_for_header: ($row, index) ->
    header = $($row.closest("table").find("thead th").eq(index))
    header.data("mobile-header") || header.text()

$ ->
  ResponsiveTable.respond()
