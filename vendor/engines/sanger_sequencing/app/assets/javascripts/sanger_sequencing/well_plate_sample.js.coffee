class SangerSequencing.Sample
  constructor: (@attributes) -> undefined

  customerSampleId: ->
    @attributes.customer_sample_id

  displayId: ->
    @attributes.id

  submission_id: ->
    @attributes.submission_id

  id: ->
    @attributes.id

  class @Blank
    submission_id: ->
      ""
    customerSampleId: ->
      ""
    displayId: ->
      ""
    id: ->
      ""

  class @Reserved
    submission_id: ->
      ""
    customerSampleId: ->
      "reserved"
    displayId: ->
      ""
    id: ->
      "reserved"
