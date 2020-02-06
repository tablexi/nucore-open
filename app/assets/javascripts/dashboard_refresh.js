document.addEventListener("DOMContentLoaded", function() {
  const dashboard = document.getElementsByClassName("js--dashboardRefresh")[0];

  function fetchAndRefresh() {
    const url = dashboard.dataset["url"] || document.location;
    fetch(url)
    .then(function (response) {
      if (response.ok) {
        response.text()
        .then(function(body) {
          dashboard.innerHTML = body;
         });
      }
    });
  }

  if (dashboard) {
    const refreshInterval = dashboard.dataset["refreshInterval"] || 5000;
    window.setInterval(fetchAndRefresh, refreshInterval);
  }
});
