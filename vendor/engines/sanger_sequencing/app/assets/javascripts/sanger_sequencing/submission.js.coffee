$ ->
  $(document).on "fields_added.nested_form_fields", (event) ->
    url = $(".edit_sanger_sequencing_submission").data("create-sample-url")
    row = $(event.target)
    customerSampleIdField = row.find(".js--customerSampleId")
    customerSampleIdField.prop("disabled", true).val("Loading...")
    $.post(url).done (sample) ->
      customerSampleIdField.prop("disabled", false).val(sample.customer_sample_id)
      row.find(".js--sampleId").val(sample.id).text(sample.id)
