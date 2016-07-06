window.vue_sanger_sequencing_well_plate_displayer_app = {
  props: ["submissions", "well-plates"]

  data: ->
    builder: new SangerSequencing.WellPlateDisplayer(@submissions, @wellPlates)

  beforeCompile: ->
    @colorBuilder = new SangerSequencing.WellPlateColors(@builder)

  ready: ->
    new AjaxModal(".js--modal", ".js--submissionModal")

  methods:
    styleForSubmissionId: (submissionId) ->
      @colorBuilder.styleForSubmissionId(submissionId)

    isInPlate: (submissionId) ->
      true

    isNotInPlate: (submissionId) ->
      !@isInPlate(submissionId)

}
