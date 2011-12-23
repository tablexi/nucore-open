$(function() {
    $('#control_mechanism').change(function() {
        var selection=$(this).val();

        if(selection == 'relay')
            $('#power-relay').show();
        else
            $('#power-relay').hide();
    });
});