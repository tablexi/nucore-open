/***
 * Upates the file count when result files are uploaded or removed
 * via modal on the admin facility Order show page.
***/

document.addEventListener("DOMContentLoaded", function() {
  const table = document.getElementsByClassName("js--orderTableRefresh")[0];

  function fetchAndRefresh() {
    const url = new URL(document.location);
    url.searchParams.set("refresh", "true");
    const headers = { Accept: "text/html" };

    fetch(url, { headers: headers })
    .then(function (response) {
      if (response.ok) {
        response.text()
        .then(function(body) {
          table.innerHTML = body;
          makeAModal()
         });
      }
    });
  }

  $("#results-file-upload-modal").on("hidden", function() {
    fetchAndRefresh()
  });

});
