window.vue_sanger_sequencing_well_plate = {
  props: ["builder", "plate-index"]
  template: "#vue-sanger-sequencing-well-plate"

  data: ->
    plateGrid: SangerSequencing.WellPlateBuilder.grid()

  beforeCompile: ->
    @colorBuilder = new SangerSequencing.WellPlateColors(@builder)

  methods:
    sampleAtCell: (cellName, plateIndex) ->
      @builder.sampleAtCell(cellName, plateIndex)

    styleForCell: (cell, plateIndex) ->
      @colorBuilder.styleForSubmissionId(@sampleAtCell(cell.name, plateIndex).submissionId())

}
