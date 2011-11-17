$(function() {
    $("#dialog").dialog({
        autoOpen: false,
        resizable: false
    });

    $('#move-res').click(function(e) {
        e.preventDefault();
        var targetUrl=$(this).attr("href");

        $("#dialog").dialog({
          buttons : {
            'Move' : function() {
              window.location.href = targetUrl;
            }
          }
        });

        $("#dialog").dialog("open");
    });
});
