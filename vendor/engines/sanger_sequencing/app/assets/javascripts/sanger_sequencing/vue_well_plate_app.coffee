window.vue_sanger_sequencing_well_plate_app = {
  props: ["submissions"]
  data: ->
    plate: SangerSequencing.WellPlateBuilder.rows()
    builder: new SangerSequencing.WellPlateBuilder

  ready: ->
    vueBus.$on "submission-added", @addSubmission
    new AjaxModal(".js--modal", ".js--submissionModal")

  methods:
    handleCellClick: (cell) ->
      # TODO: Remove
      console.log "handleCellClick", cell

    addSubmission: (submissionId) ->
      @builder.addSubmission @findSubmission(submissionId)

    sampleAtCell: (cellName) ->
      @builder.sampleAtCell(cellName)

    findSubmission: (submissionId) ->
      @submissions.filter((submission) =>
        submission.id == submissionId
      )[0]

    colorForCell: (cell) ->
      @colorForSubmissionId(@sampleAtCell(cell.name).submission_id())

    colorForSubmissionId: (submissionId) ->
      index = @submissionIndex(submissionId) + 1
      "sangerSequencing--colorCoded__color#{index}"

    submissionIndex: (submissionId) ->
      @builder.submissions.map((submission) ->
        submission.id
      ).indexOf(submissionId)

    hasBeenAdded: (submissionId) ->
      @builder.hasBeenAdded(@findSubmission(submissionId))

    hasNotBeenAdded: (submissionId) ->
      !@hasBeenAdded(submissionId)

}
