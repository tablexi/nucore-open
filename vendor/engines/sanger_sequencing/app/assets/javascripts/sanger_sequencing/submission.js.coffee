$ ->
  $(document).on "fields_added.nested_form_fields", (event) ->
    lastCustomerSampleId = $(".js--customerSampleId").last().val() || Date.now().valueOf()
    newCustomerSampleId = (lastCustomerSampleId + 1) % 10000
    $(event.target).find(".js--customerSampleId").val(newCustomerSampleId)
