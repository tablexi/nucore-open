window.vue_sanger_sequencing_bootstrap = ->
  Vue.component "vue-sanger-sequencing-well-plate-app", window.vue_sanger_sequencing_well_plate_app
  Vue.component "vue-sanger-sequencing-well-plate", window.vue_sanger_sequencing_well_plate

  window.vueBus = new Vue

  new Vue
    el: "body"
