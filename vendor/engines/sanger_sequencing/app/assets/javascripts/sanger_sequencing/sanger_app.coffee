window.sanger_app = {
  props: ["submissions"]
  data: ->
    plate: SangerSequencing.WellPlateBuilder.rows()
    builder: new SangerSequencing.WellPlateBuilder

  ready: ->
    vueBus.$on "submission-added", @addSubmission
    console.debug new SangerSequencing.WellPlateBuilder()

  methods:
    handleCellClick: (cell) ->
      console.log "handleCellClick", cell

    addSubmission: (submissionId) ->
      @builder.addSubmission @findSubmission(submissionId)

    sampleAtCell: (cellName) ->
      @builder.sampleAtCell(cellName)

    findSubmission: (submissionId) ->
      @submissions.filter((submission) =>
        submission.id == submissionId
      )[0]

    hasBeenAdded: (submissionId) ->
      @addedSubmissions.indexOf(submissionId) >= 0

    hasNotBeenAdded: (submissionId) ->
      !@hasBeenAdded(submissionId)

}
