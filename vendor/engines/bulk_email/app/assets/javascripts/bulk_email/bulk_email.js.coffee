$ ->
  selectedUserTypes = ->
    $('.bulk_email_user_type:checked').map -> @.value

  authorizedUsersSelectedOnly = ->
    user_types = selectedUserTypes()
    user_types.length == 1 && user_types[0] == 'authorized_users'

  showHideNonRestrictedProducts = ->
    # Hide non-restricted items when doing an authorized_users search
    isHideNonRestrictedProducts = authorizedUsersSelectedOnly()
    $('.search_form #products option[data-restricted=false]').each (e)->
      $(this).prop('disabled', isHideNonRestrictedProducts)
      $(this).prop('selected', false) if isHideNonRestrictedProducts

    $('.search_form #products').trigger('chosen:updated')

    # Dates do not apply for authorized users search
    $('.search_form #dates_between')
      .toggleClass('disabled', isHideNonRestrictedProducts)
      .find('input')
      .prop('disabled', isHideNonRestrictedProducts)

  $('.bulk_email_user_type')
    .change(showHideNonRestrictedProducts)
    .trigger('change')

  $('a.submit_link').click ->
    $(this).parents('form').submit()
    false

  showHideRecipientExportButton = ->
    $downloadButton = $('.js--bulk-email-export-button')
    if $('.js--bulk-email-recipient').is(':checked')
      $downloadButton.removeClass('disabled').prop('disabled', false)
    else
      $downloadButton.addClass('disabled').prop('disabled', true)

  $('.js--bulk-email-recipient')
    .change(showHideRecipientExportButton)
    .trigger('change')

  $('#bulk_email_export .js--select_all').click(showHideRecipientExportButton)
