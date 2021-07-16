/***
 * This is used for the order detail page for a facility
 * that needs to have the result file count updated
 * when a user uploads or removes files via modal
 *
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

