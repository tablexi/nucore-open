$(function() {
  function showHideNonRestrictedProducts() {
    
    // Hide non-restricted items when we're doing an authorized_users search, since they'll
    // always return nothing
    var isHideNonRestrictedProducts = ($(this).val() == 'authorized_users');
    $(".search_form #products option[data-restricted=false]").each(function(e) {
      $(this).prop('disabled', isHideNonRestrictedProducts);
      if (isHideNonRestrictedProducts) $(this).prop('selected', false);
    });
    $(".search_form #products").trigger("liszt:updated");
    
    // Dates are also inapplicable for authorized users search
    $(".search_form #dates_between").toggleClass('disabled', isHideNonRestrictedProducts).find("input").prop('disabled', isHideNonRestrictedProducts);
  }
  
  $('.search_form #search_type').change(showHideNonRestrictedProducts).trigger('change');

  $('a.submit_link').click(function() {
    $(this).parents("form").submit();
    return false;
  })

});