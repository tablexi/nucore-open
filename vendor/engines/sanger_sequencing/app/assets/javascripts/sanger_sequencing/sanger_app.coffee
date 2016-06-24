window.sanger_app = {
  props: ["submissions"],
  data: ->
    { plate: SangerSequencing.WellPlateBuilder.rows() }
  ready: ->
    console.debug new SangerSequencing.WellPlateBuilder()
  methods: {
    handleCellClick: (cell) ->
      console.log "handleCellClick", cell
  }
}
