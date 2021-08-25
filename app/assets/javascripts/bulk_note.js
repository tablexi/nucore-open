var bulkNoteCheckbox = $('#bulk-note-checkbox');
var bulkNoteInput = $('#bulk-note-input');
bulkNoteInput.hide()
var rowNoteInputs = $('.row-note-input')
var order_form = bulkNoteCheckbox.parents('form:first')

bulkNoteCheckbox.change(function(e){
  if (bulkNoteCheckbox[0].checked === true){
    bulkNoteInput.show();
    rowNoteInputs.hide();
  } else if (bulkNoteCheckbox[0].checked === false) {
    bulkNoteInput.hide();
    rowNoteInputs.show();
  }
})
