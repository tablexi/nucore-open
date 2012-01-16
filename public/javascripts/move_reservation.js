$(function() {
    $('.move-res').click(function(e) {
        e.preventDefault();

        var targetUrl=$(this).attr("href"),
            dialogSelector="#dialog" + $(this).attr('id');

        $(dialogSelector).dialog({
            resizable: false,
            buttons : {
            'Move' : function() {
                window.location.href = targetUrl;
            }
          }
        });
    });
});
