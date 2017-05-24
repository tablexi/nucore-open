$ ->
  # The modal is present on the page after ending of a reservation. Auto-log
  # the user out of their session after 60 seconds.
  $logoutModal = $("#logout_modal")
  if $logoutModal.length > 0
    $logoutModal.modal("show")
    logoutLink = $logoutModal.find(".logout").attr("href")
    window.setTimeout((-> window.location.href = logoutLink), 60000)
