class SangerSequencing.Sample
  constructor: (@attributes) -> undefined

  toString: ->
    "#{@attributes.customer_sample_id}: #{@attributes.id}"

  class @Blank
    toString: ->
      ""

  class @Reserved
    toString: ->
      "reserved"
