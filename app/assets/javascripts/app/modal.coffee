class window.AjaxModal
  constructor: (@link_selector, @modal_selector, @options = {}) ->
    $link = $(@link_selector)
    $modal = $(@modal_selector)
    success = @options['success']
    $link.click (e) ->
      e.preventDefault()
      $.ajax {
        url: $(e.target).attr('href')
        dataType: 'html'
        success: (body) ->
          $modal.html(body).modal('show')
          success() if success?
      }
