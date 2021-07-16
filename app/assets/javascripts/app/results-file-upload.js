function makeAModal() {
  new AjaxModal('a.results-file-upload', '#results-file-upload-modal', {
    loading_text: 'Loading Results Files...',
    success(modal) {
      return $('.modal a.remove-file').bind('ajax:complete', function(e) {
        e.preventDefault();
        return modal.reload();
      });
    }
  })
}

$(
  makeAModal
);

