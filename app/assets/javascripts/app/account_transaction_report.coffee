class AccountTransactionReport
  constructor: (@$element) ->

  init: ->
    @$element.click @exportAllClicked

  exportAllClicked: (event) ->
    event.preventDefault()

    $form = $($(event.target).data('form'))
    $emailField = $form.find('[name=email]')
    defaultEmail = $emailField.val()

    toAddress = prompt 'Have the report emailed to this address:', defaultEmail

    if toAddress
      $emailField.val(toAddress)
      $form.find('[name=format]').val('csv').prop('disabled', false)
      $emailField.prop('disabled', false)

      # Do an ajax request so we don't need to re-render this search page
      $.ajax(
        type: $form.attr('method'),
        url: $form.attr('action'),
        data: $form.serialize()
      ).success (responseText) ->
        Flash.info(responseText)

      # since the submit doesn't reload the page when you download the CSV, we need
      # to reset format so the normal search submit works properly
      $form.find('[name=format]').val(null).prop('disabled', true)
      $emailField.prop('disabled', true)

$ ->
  window.report = new AccountTransactionReport($('.js--exportSearchResults')).init()
