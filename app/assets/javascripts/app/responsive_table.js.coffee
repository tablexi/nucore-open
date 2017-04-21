class window.ResponsiveTable

  respond: ->
    return unless window.IS_RESPONSIVE
    $(".js--responsive_table").each (index, table) ->
      $table = $(table)
      $th = $table.find("thead th")
      $table.find("tbody tr td").prepend (index) ->
        $("<div>").addClass("responsive-header")
                  .text($th.eq(index).text())

$ ->
  (new ResponsiveTable).respond()
