$(document).ready(function() {
  if ($('#login') && $('#username')) {
    $('#username').focus();
  }

  $('.link_select').change(function(e) {
    window.location = this.value;
  });

  $('form#ajax_form').submit(function(e){
    e.preventDefault(); //Prevent the normal submission action
    var form = $(this);
    var submit = $("input[type='submit']",form);
    var submit_val = submit.val();
    submit.val("Please Wait...");
    submit.attr("disabled", true);
    jQuery.ajax({
      type: "get",
      data: form.serialize(),
      url:  form.attr('action'),
      timeout: 25000,
      success: function(r) {
        $('#result').html(r);
        submit.val(submit_val);
        submit.attr("disabled", false);
      },
      error: function() {
        $('#result').html('<p>There was an error retrieving results.  Please try again.</p>');
        submit.val(submit_val);
        submit.attr("disabled", false);
      }
    });
  });

  $('#content').click(function(e){
    var element = $(e.target);
    if (element.is('a') && element.parents('div.ajax_links').length == 1) {
      e.preventDefault(); //Prevent the normal action
      jQuery.ajax({
        url: element.attr('href'),
        timeout: 25000,
        success: function(r) {
          $('#result').html(r);
        },
        error: function() {
          $('#result').html('<p>There was an error retrieving results.  Please try again.</p>');
        }
      });
    } else {
      return;
    }
  });

  $('.sync_select').change(function(e) {
    var selected_value = this.value;
    $('.sync_select[name='+this.name+']').each(function(e) {
      this.value = selected_value;
    });
  });

  $('#filter_toggle').click(function(){
     $('#filter_container').toggle('fast');
   });

  if ($('#Use_Bulk_Note')) {
    var bulk_note_box = $('#Use_Bulk_Note');
    var bulk_place = $('#bulk-note-place');
    bulk_place.hide()
    var row_notes = $('.single-note-place')
    var order_form = bulk_note_box.parents('form:first')

    bulk_note_box.change(function(e){
      if (bulk_note_box[0].checked === true){
        bulk_place.show();
        row_notes.hide();
      } else if (bulk_note_box[0].checked === false) {
        bulk_place.hide();
        row_notes.show();
      }
    })

    order_form.submit(function(e){
      e.preventDefault
      if (bulk_note_box[0].checked === true){
        row_notes.parents('tr').find(".toggle").filter(":checked").parents("tr").find('.single-note-place').find("input").val(bulk_place.find("input").val())
      }
      e.submit
    })

  }
});

String.prototype.endsWith = function(suffix) {
  return this.indexOf(suffix, this.length - suffix.length) !== -1;
};
