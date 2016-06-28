window.SangerSequencing = new Object()

class SangerSequencing.WellPlateBuilder

  class Util
    @flattenArray: (arrays) ->
      concatFunction = (total, submission) ->
        total.concat submission
      arrays.reduce(concatFunction, [])

  constructor: ->
    @submissions = []
    # This array maintains all of the submissions that have ever been added
    # in order to keep consistent colors when removing and adding samples.
    @allSubmissions = []
    @reservedCells = ["A01", "A02"]
    @orderingStrategy = new OddFirstOrderingStrategy

  addSubmission: (submission) ->
    @submissions.push(submission) unless @isInPlate(submission)
    @allSubmissions.push(submission) unless @hasBeenAddedBefore(submission)

  removeSubmission: (submission) ->
    index = @submissions.indexOf(submission)
    @submissions.splice(index, 1) if index > -1

  isInPlate: (submission) ->
    @submissions.indexOf(submission) >= 0

  hasBeenAddedBefore: (submission) ->
    @allSubmissions.indexOf(submission) >= 0

  samples: ->
    Util.flattenArray(@submissions.map (submission) ->
      submission.samples.map (s) ->
        if s instanceof SangerSequencing.Sample then s else new SangerSequencing.Sample(s)
    )

  sampleAtCell: (cell, plateIndex = 0) ->
    @render()[plateIndex][cell]

  plateCount: ->
    Math.max(1, Math.ceil(@samples().length / @fillOrder().length))

  render: ->
    samples = @samples()
    allPlates = []

    for plate in [0..@plateCount()]
      allPlates.push(@renderPlate(samples))

    allPlates

  renderPlate: (samples) ->
    plate = {}

    for cellName in @fillOrder()
      plate[cellName] = if @reservedCells.indexOf(cellName) < 0
        if sample = samples.shift()
          sample
        else
          new SangerSequencing.Sample.Blank
      else
        new SangerSequencing.Sample.Reserved

       sample

    plate

  fillOrder: ->
    @orderingStrategy.fillOrder(@cellArray())

  @rows: ->
    for ch in "ABCDEFGH"
      name: ch
      cells: for num in ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
        column: num
        name: "#{ch}#{num}"

  cellArray: ->
    cells = for num in ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
      for ch in "ABCDEFGH"
        "#{ch}#{num}"

  class OddFirstOrderingStrategy
    fillOrder: (cellsByColumn) ->
      odds = (column for column, i in cellsByColumn when i % 2 == 0)
      evens = (column for column, i in cellsByColumn when i % 2 == 1)
      Util.flattenArray(odds.concat(evens))
