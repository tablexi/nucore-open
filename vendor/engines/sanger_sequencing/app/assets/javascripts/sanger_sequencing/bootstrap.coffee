window.bootstrap = ->
  Vue.component "vue-sanger-app", window.sanger_app

  new Vue
    el: "body",
    data: {
      message: "Hello,"
    }



