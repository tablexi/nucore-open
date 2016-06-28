window.vue_sanger_sequencing_well_plate = {
  props: ["builder", "plate-index"]
  template: "#vue-sanger-sequencing-well-plate"
  data: ->
    plateGrid: SangerSequencing.WellPlateBuilder.rows()

  methods:
    handleCellClick: (cell) ->
      # TODO: Remove
      console.log "handleCellClick", cell

    sampleAtCell: (cellName, plateIndex) ->
      @builder.sampleAtCell(cellName, plateIndex)

    colorForCell: (cell, plateIndex) ->
      @colorForSubmissionId(@sampleAtCell(cell.name, plateIndex).submission_id())

    colorForSubmissionId: (submissionId) ->
      # 18 is a magic number coming from the number of colors we have defined in
      # our CSS classes
      index = (@submissionIndex(submissionId) % 18) + 1
      "sangerSequencing--colorCoded__color#{index}"

    submissionIndex: (submissionId) ->
      @builder.allSubmissions.map((submission) ->
        submission.id
      ).indexOf(submissionId)
}
