
var oldText = 'All Facilities'
$(document).ready(function () {
    oldText = $('.allHeader').text()
})
$(document).on('click', '.azListing', function () {
    $('.facilityListing').hide();

    var category = $(this).attr('class').replace('azListing','').replace(' ','')
    if (category === 'recent') $('.recent').show()
    else if (category === 'all') {
        $('.allHeader').text(oldText)
        $('.facilityListing').show()
    }
    else {
        $('.' + category).show()
        $('.allHeader').show()
        $('.allHeader').text(category)
    }
});
