$(function() {
  var dialog = null;

  function pickAccessoriesHandleResponse(e, jqXHR, status) {
    var response = jqXHR.responseText;
    
    dialog.html(response);

    // close dialog if ajax call succeeded
    if (status == "success") {
      dialog.dialog('close');
    }
    return false;
  }

  $('body').on('click', '.has_accessories', function() {
    
    var clicked = $(this)
      , url = clicked.attr('href');

    // Hide any tooltips
    if ($('.tip').length > 0) $('.tip').data('tooltipsy').hide();

    // set closure's dialog so other handler(s) can find it
    dialog = $('#pick_accessories_dialog');

    // build dialog if necessary
    if (dialog.length == 0) {
      dialog = $('<div id="pick_accessories_dialog" style="display:none"/>');
      $("body").append(dialog);
    }

    // when the dialog closes, reload this page since the link shouldn't be there anymore
    dialog.on('dialogclose', function() { window.location.reload(); return false; });
    // call the response handler when the form inside submits
    dialog.on('ajax:complete', 'form.pick_accessories_form', pickAccessoriesHandleResponse);
    // Disable inputs
    dialog.on('submit', 'form.pick_accessories_form', function() {
      $(this).find('input[type=submit]').prop('disabled', true);
    });

    if (!clicked.hasClass('persistent')) { 
      clicked.fadeOut();
    }

    // load pick_accessories_form into dialog
    dialog.load(
      url,
      function(response, status, xhr) {
        // show dialog
        dialog.dialog({
          closeOnEscape:  false,
          modal:          true,
          title:          'Accessories Entry',
          zIndex:         10000
        });
      }
    );

    return false;
  });

  $(document).on('click', '#cancel-btn', function(e) {
    e.preventDefault();
    $('#pick_accessories_dialog').dialog('close');
  });

});
