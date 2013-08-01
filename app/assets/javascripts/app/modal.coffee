class window.AjaxModal
  constructor: (@link_selector, @modal_selector, @options = {}) ->
    $link = $(@link_selector)
    @$modal = $modal = $(@modal_selector)
    if @$modal.length == 0
      @$modal = $modal = @build_new_modal()

    success = @options['success']
    form_prepare = @form_prepare

    @loading_text = @options.loading_text || 'Loading...'

    self = this

    $link.click (e) ->
      e.preventDefault()
      $modal.modal('show')
      $modal.data('href', $(this).attr('href'))
      $modal.data('modalObject', self)
      self.reload()


  form_prepare: =>
    self = this

    form = @$modal.find('form')
    form.bind 'submit', ->
      form.find('input[type=submit]').prop('disabled', true)

    form.bind 'ajax:error', @form_error
    form.bind 'ajax:success', (evt, xhr, c) ->
      self.form_success(xhr.responseText)

    @$modal.trigger('modal:loaded')

    success = @options['success']
    success(self) if success?

  form_success: (body) =>
    window.location.reload()

  form_error: (evt, xhr) =>
    @$modal.html(xhr.responseText)
    @form_prepare()

  build_new_modal: ->
    modal = $('<div class="modal hide fade" data-backdrop="static"></div>')
    modal.attr('id', @modal_selector.replace('#', ''))
    modal.appendTo('body')

  reload: =>
    $modal = @$modal
    self = this
    $modal.html("<div class='modal-body'><h3>#{@loading_text}</h3></div>")
    $.ajax {
      url: $modal.data('href')
      dataType: 'html'
      success: (body) ->
        $modal.html(body)
        self.form_prepare()
    }
