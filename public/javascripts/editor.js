$(document).ready(function() {
  if (! CKEDITOR) return;
  $('textarea.editor').each(function(){
    CKEDITOR.replace(this.id, { 
      toolbar: 
        [
          ['Source','-','Preview'],
          ['Cut','Copy','Paste','PasteText','PasteFromWord','SpellChecker','Scayt'],
          ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
          ['Maximize', 'ShowBlocks'],
          '/',
          ['Bold','Italic','Underline'],
          ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote'],
          ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
          ['Link','Unlink'],
          ['Image','Table','HorizontalRule','SpecialChar'],
          ['TextColor']
        ],
      resize_enabled: true
    });
  });
});
