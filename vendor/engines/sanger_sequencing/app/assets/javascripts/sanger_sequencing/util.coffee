exports = exports ? @
exports.SangerSequencing = new Object unless exports.SangerSequencing

class exports.SangerSequencing.Util
  @flattenArray: (arrays) ->
    concatFunction = (total, submission) ->
      total.concat submission
    arrays.reduce(concatFunction, [])
