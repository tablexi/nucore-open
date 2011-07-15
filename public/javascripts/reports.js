function getParamsString()
{
    return '?date_start=' + $('#date_start').val() + '&date_end=' + $('#date_end').val() + '&status_filter=' + $('#status_filter').val();
}

function createGeneralReportsTable(selectedIndex)
{
    $('#tabs').tabs({
        selected: selectedIndex,
        ajaxOptions: {
          error: function(xhr, status, error) {
            $('#error-msg').html('Sorry, but the tab could not load. Please try again soon.').show();
          },

          beforeSend: function(xhr) {
            xhr.open(this.type, this.url + getParamsString(), this.async);
          }
        }
    });

    // capture a click on the refresh button and defer work to jQuery UI's tabs
    $('#refresh-form').bind('ajax:beforeSend', function(event, xhr) {
       var selected=$('#tabs').tabs('option', 'selected');
       $('#tabs').tabs('load', selected);
       return false;
    })
}

$(document).ready(function() {
    $('.datepicker').each(function() {
      $(this).datepicker();
    });
});