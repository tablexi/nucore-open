window.vue_sanger_sequencing_well_plate = {
  props: ["builder", "plate-index"]
  template: "#vue-sanger-sequencing-well-plate"
  data: ->
    plateGrid: SangerSequencing.WellPlateBuilder.grid()

  methods:
    handleCellClick: (cell) ->
      # TODO: Remove
      console.log "handleCellClick", cell

    sampleAtCell: (cellName, plateIndex) ->
      @builder.sampleAtCell(cellName, plateIndex)

    styleForCell: (cell, plateIndex) ->
      @colorBuilder ||= new SangerSequencing.WellPlateColors(@builder)
      @colorBuilder.styleForSubmissionId(@sampleAtCell(cell.name, plateIndex).submission_id())

}
