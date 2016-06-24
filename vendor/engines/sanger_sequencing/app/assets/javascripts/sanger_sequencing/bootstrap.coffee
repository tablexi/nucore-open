window.bootstrap = ->
  Vue.component "vue-sanger-app", window.sanger_app

  window.bus = new Vue

  new Vue
    el: "body",
    methods:
      handleAdd: (submissionId) ->
        bus.$emit("submission-added", submissionId)

