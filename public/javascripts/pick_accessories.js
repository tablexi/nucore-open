(function() {
  var dialog = null;

  // set up handler for any form w/in the dialog
  $('#pick_accessories_dialog form.pick_accessories_form').live('ajax:complete', function(e, jqXHR, status) {
    var response = jqXHR.responseText;
    
    dialog.html(response);

    // close dialog if ajax call succeeded
    if (status == "success") {
      dialog.dialog('close');
      window.location = window.location.href;
    }

    return false;
  });

  $('.end_reservation_link').live('click', function() {
    var clicked = $(this)
      , url = clicked.attr('href');

    // set closure's dialog so other handler(s) can find it
    dialog = $('#dialog');

    // build dialog if necessary
    if (dialog.length == 0) {
      dialog = $('<div id="pick_accessories_dialog" style="display:hidden"/>');
      clicked.after(dialog);
    }

    // load pick_accessories_form into dialog
    dialog.load(
      url,
      function(response, status, xhr) {
        // show dialog
        dialog.dialog();
      }
    ); 

    return false;
  });

})();
