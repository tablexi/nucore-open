window.vue_sanger_sequencing_well_plate_app = {
  props: ["submissions"]
  data: ->
    builder: new SangerSequencing.WellPlateBuilder

  ready: ->
    vueBus.$on "submission-added", @addSubmission
    new AjaxModal(".js--modal", ".js--submissionModal")

  methods:
    addSubmission: (submissionId) ->
      @builder.addSubmission @findSubmission(submissionId)

    removeSubmission: (submissionId) ->
      @builder.removeSubmission @findSubmission(submissionId)

    findSubmission: (submissionId) ->
      @submissions.filter((submission) =>
        submission.id == submissionId
      )[0]

    colorForCell: (cell) ->
      @colorForSubmissionId(@sampleAtCell(cell.name).submission_id())

    colorForSubmissionId: (submissionId) ->
      # 18 is a magic number coming from the number of colors we have defined in
      # our CSS classes
      index = (@submissionIndex(submissionId) % 18) + 1
      "sangerSequencing--colorCoded__color#{index}"

    submissionIndex: (submissionId) ->
      @builder.allSubmissions.map((submission) ->
        submission.id
      ).indexOf(submissionId)

    isInPlate: (submissionId) ->
      @builder.isInPlate(@findSubmission(submissionId))

    isNotInPlate: (submissionId) ->
      !@isInPlate(submissionId)

}
