#= require sanger_sequencing/util
#= require sanger_sequencing/columns_first_ordering_strategy

exports = exports ? @

class exports.SangerSequencing.OddFirstOrderingStrategy
  fillOrder: ->
    odds = (column for column, i in @_cellsByColumn() when i % 2 == 0)
    evens = (column for column, i in @_cellsByColumn() when i % 2 == 1)
    SangerSequencing.Util.flattenArray(odds.concat(evens))

  _cellsByColumn: ->
    new SangerSequencing.ColumnsFirstOrderingStrategy().cellsByColumn()
