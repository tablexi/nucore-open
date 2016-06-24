window.sanger_app = {
  props: ["submissions"]
  data: ->
    plate: SangerSequencing.WellPlateBuilder.rows()
    addedSubmissions: []

  ready: ->
    bus.$on "submission-added", @addSubmission
    console.debug new SangerSequencing.WellPlateBuilder()

  methods:
    handleCellClick: (cell) ->
      console.log "handleCellClick", cell

    addSubmission: (submissionId) ->
      @addedSubmissions.push(submissionId) unless @hasBeenAdded(submissionId)
      console.debug @addedSubmissions

    hasBeenAdded: (submissionId) ->
      @addedSubmissions.indexOf(submissionId) >= 0

    hasNotBeenAdded: (submissionId) ->
      !@hasBeenAdded(submissionId)

}
