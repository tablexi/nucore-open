class window.AjaxModal
  constructor: (@link_selector, @modal_selector, @options = {}) ->
    $link = $(@link_selector)
    @$modal = $modal = $(@modal_selector)
    success = @options['success']
    form_prepare = @form_prepare

    $link.click (e) ->
      e.preventDefault()
      $modal.modal('show')
      $modal.html('') # clear it out
      $.ajax {
        url: $(e.target).attr('href')
        dataType: 'html'
        success: (body) ->
          $modal.html(body)
          form_prepare()
      }


  form_prepare: =>
    self = this

    form = @$modal.find('form')
    form.bind 'submit', ->
      form.find('input[type=submit]').prop('disabled', true)

    form.bind 'ajax:error', @form_error
    form.bind 'ajax:success', (evt, xhr, c) ->
      self.form_success(xhr.responseText)

    success = @options['success']
    success() if success?

  form_success: (body) =>
    window.location.reload()

  form_error: (evt, xhr) =>
    @$modal.html(xhr.responseText)
    @form_prepare()



