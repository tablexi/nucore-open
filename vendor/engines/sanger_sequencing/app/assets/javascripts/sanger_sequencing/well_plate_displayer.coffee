class SangerSequencing.WellPlateDisplayer
  constructor: (@submissions, @wellPlates) ->
    @allSubmissions = @submissions
    @sampleCache = {}

  plateCount: ->
    @wellPlates.length

  sampleAtCell: (position, plateIndex) ->
    attrs = @wellPlates[plateIndex][position]

    switch attrs
      when "reserved" then new SangerSequencing.Sample.Reserved
      when "" then new SangerSequencing.Sample.Blank
      else new SangerSequencing.Sample(attrs)
