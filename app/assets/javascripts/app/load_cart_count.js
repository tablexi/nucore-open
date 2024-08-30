function loadCartCount(cart) {
  const element = $(cart);

  if (!element) { return; }

  let url = element.data("url");

  if (!url) { return; }

  url = new URL(url);

  fetch(url,).then(function (response) {
    if (response.ok) {
      response.text().then(function (data) {
        data = JSON.parse(data);
        const count = data.data.count;
        const text = `Cart (${count})`;

        const anchorElement = element.find("a");
        anchorElement.text(text);
      });
    } else {
      console.error("There was an error fetching the cart order details count");
    }
  });
}

$(function () {
  return loadCartCount(".js--cart_count");
});
