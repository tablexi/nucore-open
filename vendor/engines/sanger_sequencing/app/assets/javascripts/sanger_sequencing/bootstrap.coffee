window.bootstrap = ->
  Vue.component "vue-sanger-app", window.sanger_app

  window.vueBus = new Vue

  new Vue
    el: "body",
    methods:
      handleAdd: (submissionId) ->
        vueBus.$emit("submission-added", submissionId)

