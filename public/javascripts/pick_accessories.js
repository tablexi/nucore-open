(function() {
  var dialog = null;

  // set up handler for any form w/in the dialog
  $('#pick_accessories_dialog form.pick_accessories_form').live('ajax:complete', function(e, jqXHR, status) {
    var response = jqXHR.responseText;
    
    dialog.html(response);

    // close dialog if ajax call succeeded
    if (status == "success") {
      dialog.dialog('close');
    }

    return false;
  });
  
  // when the dialog closes, reload this page since the link shouldn't be there anymore
  $('#pick_accessories_dialog').live('dialogclose', function() {
    window.location = window.location.href;
  });

  $('.has_accessories').live('click', function() {
    var clicked = $(this)
      , url = clicked.attr('href');

    // set closure's dialog so other handler(s) can find it
    dialog = $('#pick_accessories_dialog');

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
        dialog.dialog({
          closeOnEscape:  false,
          modal:          true,
          title:          'Accessories Entry'
        });
      }
    ); 

    return false;
  });

})();
