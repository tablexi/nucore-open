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

    colorForSubmissionId: (submissionId) ->
      @colorBuilder ||= new SangerSequencing.WellPlateColors(@builder)
      @colorBuilder.colorForSubmissionId(submissionId)

    isInPlate: (submissionId) ->
      @builder.isInPlate(@findSubmission(submissionId))

    isNotInPlate: (submissionId) ->
      !@isInPlate(submissionId)

}
