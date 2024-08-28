window.Cart = class Cart {
  constructor($cart) {
    this.$cart = $cart;
  }

  loadCartCount() {
    const element = $(this.$cart);

    if (!element) { return; }

    const url = element.data("url");
    const link = element.data("link");

    return $.ajax({
      type: "get",
      url,
      dataType: "text",
      success(data) {
        data = JSON.parse(data);
        const count = data.data.count;
        const text = `Cart (${count})`;

        const anchorElement = document.createElement("a");
        anchorElement.setAttribute("href", link);
        anchorElement.innerHTML = text;

        element.append(anchorElement);
      }
    })
  }
}

$(function () {
  const cart = new Cart(".js--cart_count");
  return cart.loadCartCount();
});
