window.CartCount = class CartCount {
  constructor($cart) {
    this.$cart = $cart;
  }

  loadCartCount() {
    const element = $(this.$cart);

    if (!element) { return; }

    let url = element.data("url");

    if (!url) { return; }

    url = new URL(url);

    fetch(url, { mode: "no-cors" }).then(function (response) {
      if (response.ok) {
        response.text().then(function (data) {
          data = JSON.parse(data);
          const count = data.data.count;
          const text = `Cart (${count})`;

          const anchorElement = element.find("a");
          anchorElement.text(text);
        });
      }
    });
  }
};

$(function () {
  const cart = new CartCount(".js--cart_count");
  return cart.loadCartCount();
});
