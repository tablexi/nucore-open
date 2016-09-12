$(function() {

  function selectedUserTypes() {
    return $('.bulk_email_user_type:checked').map(function () { return this.value });
  }

  function authorizedUsersSelectedOnly() {
    var user_types = selectedUserTypes();
    return user_types.length == 1 && user_types[0] == 'authorized_users';
  }

  function showHideNonRestrictedProducts() {

    // Hide non-restricted items when we're doing an authorized_users search, since they'll
    // always return nothing
    var isHideNonRestrictedProducts = authorizedUsersSelectedOnly();
    $(".search_form #products option[data-restricted=false]").each(function(e) {
      $(this).prop('disabled', isHideNonRestrictedProducts);
      if (isHideNonRestrictedProducts) $(this).prop('selected', false);
    });
    $(".search_form #products").trigger("chosen:updated");

    // Dates are also inapplicable for authorized users search
    $(".search_form #dates_between").toggleClass('disabled', isHideNonRestrictedProducts).find("input").prop('disabled', isHideNonRestrictedProducts);
  }

  $('.bulk_email_user_type').change(showHideNonRestrictedProducts).trigger('change');

  function showHideRecipientExportButton() {
    var $downloadButton = $('.js--bulk-email-export-button');
    if ($('.js--bulk-email-recipient').is(':checked')) {
      $downloadButton.removeClass("disabled").prop("disabled", false)
    }
    else {
      $downloadButton.addClass("disabled").prop("disabled", true)
    }
  }

  $('.js--bulk-email-recipient').change(showHideRecipientExportButton).trigger('change');
  $('#bulk_email_export .js--select_all').click(showHideRecipientExportButton);
});
