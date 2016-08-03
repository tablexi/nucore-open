#= require sanger_sequencing/util
exports = exports ? @

class exports.SangerSequencing.RowsFirstOrderingStrategy
  fillOrder: ->
    SangerSequencing.Util.flattenArray(@cellsByRow())

  cellsByRow: ->
    for ch in "ABCDEFGH"
      for num in ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
        "#{ch}#{num}"
