$ ->
  class SangerSequencingSampleArray
    constructor: (@url) ->
      @availableIds = []

    # Accepts a callback that will get called as soon as an ID is available
    shift: (callback) =>
      if @availableIds.length > 0
        callback(@availableIds.shift())
      else
        $.get(@url)
          .done (data) =>
            @availableIds = @availableIds.concat(data)
            callback(@availableIds.shift())

  class SangerSequencingSubmission
    constructor: (fetcher_url) ->
      @ids = new SangerSequencingSampleArray(fetcher_url)

    fieldsAdded: (event, param) =>
      customerSampleIdField = $(event.target).find(".js--customerSampleId")
      customerSampleIdField.prop("disabled", true).val("Loading...")
      idField = $(event.target).find(".js--sampleId")

      @ids.shift (sample_data) ->
        customerSampleIdField.val(sample_data.customer_sample_id).prop("disabled", false)
        idField.val(sample_data.id).text(sample_data.id)

  fetchDataUrl = $(".edit_sanger_sequencing_submission").data("fetch-ids-url")
  submission = new SangerSequencingSubmission(fetchDataUrl)
  $(document).on "fields_added.nested_form_fields", submission.fieldsAdded
