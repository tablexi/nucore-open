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

      $form.submit()

      # since the submit doesn't reload the page when you download the CSV, we need
      # to reset format so the normal search submit works properly
      $form.find('[name=format]').val(null).prop('disabled', true)
      $emailField.prop('disabled', true)

$ ->
  window.report = new AccountTransactionReport($('.js--exportSearchResults')).init()
