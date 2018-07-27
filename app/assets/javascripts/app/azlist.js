$(document).on('click', '.azListing', function () {
    var letter = $(this).text()[1]
    $('.facilityListing').hide();
    $('.' + letter).show()
});


