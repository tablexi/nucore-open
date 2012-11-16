/**
 * A query string of all params necessary to issue a report.
 * @params
 * A variable number of additional parameter Arrays.
 * Each Array is expected to be length 2 where index
 * 0 holds the name of a parameter and index 1 holds
 * a value. These will be appended to the end of the
 * default query string.
 */

// get a query string with the most current report parameters
function getQueryString()
{
    var paramString='?' + $('#refresh-form').serialize();

    for(var param in arguments)
        paramString += ('&' + param);

    return paramString;
}


// update the given url with the most current report parameters
function updateUrl(url)
{
    var pageParam=url.match(/page=\d+/);

    if(pageParam != null)
        return url.substring(0, url.indexOf('?')) + getQueryString(pageParam[0]);

    return url + getQueryString();
}


// returns the 0-based index of the currently selected tab
function getSelectedTabIndex() { return $('#tabs').tabs().tabs('option', 'selected'); }


// update and return the currently selected tab's URL
function getUpdateTabUrl(ui)
{
    if(ui != null)
        return updateUrl($.data(ui.tab, 'load.tabs'));

    var links=$("#tabs > ul").find("li a");
    return updateUrl($.data(links[getSelectedTabIndex()], 'href.tabs'));
}


function updateReport()
{
    var selected=getSelectedTabIndex();
    $('#tabs').tabs('url', selected, getUpdateTabUrl()).tabs('load', selected);
}


function initReportsUI(selectedIndex)
{
    // create reports tabs
    $('#tabs').tabs({
        selected: selectedIndex,

        select: function(event, ui) {
            // before refreshing tab update the tab's URL with the current report params
            var url=getUpdateTabUrl(ui);
            $('#tabs').tabs('url', ui.index, url);
        },

        load: function(event, ui) {
            // every time a tab loads make sure the export urls are set to export current report
            var url=getUpdateTabUrl(ui);
            $('#export').attr('href', url + '&export_id=report&format=csv');
            $('#export-all').attr('href', url + '&export_id=report_data&format=csv');

            // Make sure to update the date params in case they were empty or invalid
            $('#date_start').val($(ui.panel).find('.updated_values .date_start').text())
            $('#date_end').val($(ui.panel).find('.updated_values .date_end').text())
            
        },

        ajaxOptions: {
            dataType: "text html",
            error: function(xhr, status, error) {
                $('#error-msg').html('Sorry, but the tab could not load. Please try again soon.').show();
            }
        }
    });

    // handle pagination requests
    $(document).on('click', '.pagination a', function (){
        var selected=getSelectedTabIndex();
        $('#tabs').tabs('url', selected, this.href).tabs('load', selected);
        return false;
    });

    // update report on parameter change
    $('#refresh-form :input').change(updateReport);

    // decorate order status drop down
    if($('#status_filter').length)
        $('#status_filter').chosen();
}


$(function() {
    $('.datepicker').each(function() {
      $(this).datepicker();
    });
});
