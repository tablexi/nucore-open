class window.CartQuantityReplacer
  constructor: (@originalPath, @newQuantity) -> undefined

  toString: ->
    @originalPath.replace(/\bquantity=\d+(&|$)/, "quantity=#{@newQuantity}$1")

$ ->
  class Cart
    constructor: (cartSelector) ->
      @$cart = $(cartSelector)
      @$cart.find("[data-quantity-field]").each @setupQuantityListeners

    setupQuantityListeners: (i, link) ->
      trackedField = $(link).data("quantity-field")
      $("##{trackedField}").change ->
        newQuantity = $(@).val()
        link.href = new CartQuantityReplacer(link.href, newQuantity)

  new Cart ".js--cart"
