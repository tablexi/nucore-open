class SangerSequencing.Sample
  constructor: (@attributes) -> undefined

  customerSampleId: ->
    @attributes.customer_sample_id

  displayId: ->
    @attributes.id

  submissionId: ->
    @attributes.submission_id

  id: ->
    @attributes.id

  class @Blank
    submissionId: ->
      ""
    customerSampleId: ->
      ""
    displayId: ->
      ""
    id: ->
      ""

  # Treated as blank in the backend, but displays like reserved
  class @ReservedButUnused
    submissionId: ->
      ""
    customerSampleId: ->
      "reserved"
    displayId: ->
      ""
    id: ->
      ""


  class @Reserved
    submissionId: ->
      ""
    customerSampleId: ->
      "reserved"
    displayId: ->
      ""
    id: ->
      "reserved"
