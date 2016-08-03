#= require sanger_sequencing/util
exports = exports ? @

class exports.SangerSequencing.ColumnsFirstOrderingStrategy
  fillOrder: ->
    SangerSequencing.Util.flattenArray(@cellsByColumn())

  cellsByColumn: ->
    for num in ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
      for ch in "ABCDEFGH"
        "#{ch}#{num}"
