$(function() {
  $('.move-res').click(function(e) {
    e.preventDefault();

    var targetUrl      = $(this).attr("href");
    var dialogSelector = "#dialog" + $(this).attr('id');

    jQuery.ajax({
      url: targetUrl,
      dataType: 'html',
      success: function(data) {
        $(dialogSelector).html(data);
        moveButton.button('enable');
      },
      error: function() {
        $(dialogSelector).html('There was an error retrieving earliest possible move date.');
      }
    });

    $(dialogSelector).html('Finding next available reservation time...');

    $(dialogSelector).dialog({
      resizable: false,
      buttons : {
        'Move' : function() {
          $(this).find('form').submit();
          moveButton.button('disable');
          $(this).html('Moving reservation...');
        }
      }
    });

    var moveButton = $(dialogSelector).closest('.ui-dialog').find('button');
    moveButton.button('disable');
  });
});
