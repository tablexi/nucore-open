$ ->

  addCheckboxChangeHandler = ($row)->
    $checkbox = $row.find(":checkbox")
    $select = $row.find("select")
    $checkbox.on "change", -> $select.prop(disabled: !this.checked)
    $checkbox.change()

  $(".js--access-list-row").each -> addCheckboxChangeHandler($(this))
