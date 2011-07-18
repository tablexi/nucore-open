function getParamsString()
{
    return '?date_start=' + $('#date_start').val() + '&date_end=' + $('#date_end').val() + '&status_filter=' + $('#status_filter').val();
}

function createGeneralReportsTable(selectedIndex)
{
    // create tabbed reports
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

    // update report on refresh button click
    $('#refresh button').button().click(function() {
        var selected=$('#tabs').tabs('option', 'selected');
        $('#tabs').tabs('load', selected);
        return false;
    });

    // report export options
    $('#export button:first').button().click(function() {
        alert( "Export Screen" );
    })
    .next().button( {
        text: false,
        icons: {
            primary: "ui-icon-triangle-1-s"
        }
    })
    .click(function() {
        $(this).next().toggle();
    })
    .parent().buttonset();
}

$(document).ready(function() {
    $('.datepicker').each(function() {
      $(this).datepicker();
    });
});