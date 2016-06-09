class SangerSequencing.Sample
  constructor: (@id, @customer_sample_id) -> undefined

  toString: ->
    @customer_sample_id.toString()

  class @Blank
    toString: ->
      ""

  class @Reserved
    toString: ->
      "reserved"
