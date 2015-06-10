class AccountTransactionReport
  constructor: (@$element) ->
    return unless @$element.length > 0
    @registerExportAllHandler()

  registerExportAllHandler: ->
    $('#js--exportAll').click (event) => @exportAllClicked(event)

  exportAllClicked: (event) ->
    newTo = prompt 'Have the report emailed to this address:', $('#js--toEmail').val()

    if newTo
      url = event.target.href
      $.post(url, { to_email: newTo }, ->
        $status = $('#js--exportStatus')
        $status.text("Successfully sent report")
        $status.show()
        setTimeout( ->
          $status.fadeOut()
        , 5000);
      )

    event.preventDefault()

$ ->
  window.report = new AccountTransactionReport($('#table_billing'))
