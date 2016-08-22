window.vue_sanger_sequencing_well_plate_editor_app = {
  props: ["submissions", "builder_config"]

  data: ->
    builder: new SangerSequencing.WellPlateBuilder

  beforeCompile: ->
    @colorBuilder = new SangerSequencing.WellPlateColors(@builder)
    @builder.setReservedCells(@builder_config.reserved_cells)

  ready: ->
    new AjaxModal(".js--modal", ".js--submissionModal")

  methods:
    addSubmission: (submissionId) ->
      @builder.addSubmission @findSubmission(submissionId)

    removeSubmission: (submissionId) ->
      @builder.removeSubmission @findSubmission(submissionId)

    submissionIds: ->
      @builder.submissions.map (submission) ->
        submission.id

    findSubmission: (submissionId) ->
      @submissions.filter((submission) =>
        submission.id == submissionId
      )[0]

    styleForSubmissionId: (submissionId) ->
      @colorBuilder.styleForSubmissionId(submissionId)

    isInPlate: (submissionId) ->
      @builder.isInPlate(@findSubmission(submissionId))

    isNotInPlate: (submissionId) ->
      !@isInPlate(submissionId)

}
