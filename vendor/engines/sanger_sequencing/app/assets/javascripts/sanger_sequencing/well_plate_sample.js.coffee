class SangerSequencing.Sample
  constructor: (@attributes) -> undefined

  toString: ->
    @attributes.customer_sample_id

  submission_id: ->
    @attributes.submission_id

  id: ->
    @attributes.id

  class @Blank
    toString: ->
      ""
    submission_id: ->
      ""
    id: ->
      ""

  class @Reserved
    toString: ->
      "reserved"
    submission_id: ->
      ""
    id: ->
      ""
