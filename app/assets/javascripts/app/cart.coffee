$ ->
  class Cart
    constructor: (cartSelector) ->
      @$cart = $(cartSelector)
      @$cart.find("[data-quantity-field]").each @setupQuantityListeners

    setupQuantityListeners: (i, link) ->
      trackedField = $(link).data("quantity-field")
      $("##{trackedField}").change ->
        newQuantity = $(@).val()
        link.href = link.href.replace(/quantity=\d+&/, "quantity=#{newQuantity}&")

  new Cart ".js--cart"
