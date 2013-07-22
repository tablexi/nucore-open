$ ->
  new AjaxModal('a.results-file-upload', '#results-file-upload-modal', {
    loading_text: 'Loading Results Files...',
    success: (modal) ->
      $('.modal a.remove-file').bind 'ajax:complete', (e) ->
        e.preventDefault()
        modal.reload()
    })
