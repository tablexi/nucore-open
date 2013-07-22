$ ->
  $("fieldset.collapsable").each ->
    $this = $(this)
    $this.find("> :not(.legend)").toggle(!$this.hasClass("collapsed"))
    $this.enableDisableFields = ->
      this.find("input, select").prop('disabled', $this.hasClass('collapsed'))

    $this.enableDisableFields()
    $this.find(".legend").click ->
      # $this is still the fieldset, but 'this' is legend
      $this.toggleClass("collapsed").find("> :not(.legend)").slideToggle()
      $this.enableDisableFields()
