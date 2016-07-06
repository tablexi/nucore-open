window.vue_sanger_sequencing_bootstrap = ->
  Vue.component "vue-sanger-sequencing-well-plate-editor-app", window.vue_sanger_sequencing_well_plate_editor_app
  Vue.component "vue-sanger-sequencing-well-plate-displayer-app", window.vue_sanger_sequencing_well_plate_displayer_app
  Vue.component "vue-sanger-sequencing-well-plate", window.vue_sanger_sequencing_well_plate

  window.vueBus = new Vue

  new Vue
    el: "body"
