$ ->
  $(document).on "fields_added.nested_form_fields", (event) ->
    sangerSequencingForm = $("form.edit_sanger_sequencing_submission")
    return unless sangerSequencingForm.length > 0
    row = $(event.target)
    customerSampleIdField = row.find(".js--customerSampleId")
    customerSampleIdField.prop("disabled", true).val("Loading...")
    $.post(sangerSequencingForm.data("create-sample-url")).done (sample) ->
      customerSampleIdField.prop("disabled", false).val(sample.customer_sample_id)
      row.find(".js--sampleId").val(sample.id).text(sample.id)
