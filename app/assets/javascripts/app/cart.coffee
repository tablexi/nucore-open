class window.CartQuantityReplacer
  constructor: (@originalPath, @newQuantity) -> undefined

  toString: ->
    @originalPath.replace(/\bquantity=\d+(&|$)/, "quantity=#{@newQuantity}$1")

class window.Cart
  constructor: (cartSelector) ->
    @$cart = $(cartSelector)
    @$cart.find("[data-quantity-field]").each @setupQuantityListeners

  setupQuantityListeners: (_i, link) ->
    $link = $(link)
    $quantityField = $("#" + $(link).data("quantity-field"))
    originalHref = $link.attr("href")

    $quantityField.change (e) ->
      newQuantity = parseInt($quantityField.val())

      if newQuantity > 0
        $link
          .removeClass("disabled")
          .attr("href", new CartQuantityReplacer(originalHref, newQuantity))

      else
        $link
          .addClass("disabled")
          .removeAttr("href")

$ ->
  new Cart ".js--cart"
