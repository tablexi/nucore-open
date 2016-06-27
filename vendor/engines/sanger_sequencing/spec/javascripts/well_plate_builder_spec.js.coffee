#= require sanger_sequencing/well_plate

describe "SangerSequencing.WellPlateBuilder", ->
  sampleList = (count) ->
    @lastSampleId = 0 if @lastSampleId == undefined
    for x in [0...count]
      @lastSampleId++
      new SangerSequencing.Sample(id: @lastSampleId, customer_sample_id: "Testing #{x}")

  describe "addSubmission()", ->
    beforeEach ->
      @submission = { id: 542, samples: sampleList(2) }
      @wellPlate = new SangerSequencing.WellPlateBuilder

    it "can add a submission", ->
      @wellPlate.addSubmission(@submission)
      expect(@wellPlate.submissions).toEqual([@submission])

    it "cannot add a submission twice", ->
      @wellPlate.addSubmission(@submission)
      @wellPlate.addSubmission(@submission)
      expect(@wellPlate.submissions).toEqual([@submission])

  describe "removeSubmission()", ->
    beforeEach ->
      @wellPlate = new SangerSequencing.WellPlateBuilder
      @submission1 = { id: 542, samples: sampleList(2) }
      @submission2 = { id: 543, samples: sampleList(3) }
      @wellPlate.addSubmission(@submission1)
      @wellPlate.addSubmission(@submission2)

    it "can remove a submission", ->
      @wellPlate.removeSubmission(@submission1)
      expect(@wellPlate.submissions).toEqual([@submission2])

  describe "samples()", ->
    beforeEach ->
      @wellPlate = new SangerSequencing.WellPlateBuilder
      @submission1 = { id: 542, samples: sampleList(2) }
      @submission2 = { id: 543, samples: sampleList(3) }
      @wellPlate.addSubmission(@submission1)
      @wellPlate.addSubmission(@submission2)

    it "returns the samples in order", ->
      expect(@wellPlate.samples()).toEqual(@submission1.samples.concat @submission2.samples)

  describe "sampleAtCell()", ->
    beforeEach ->
      @wellPlate = new SangerSequencing.WellPlateBuilder
      @submission1 = { id: 542, samples: sampleList(2) }
      @submission2 = { id: 543, samples: sampleList(3) }
      @wellPlate.addSubmission(@submission1)
      @wellPlate.addSubmission(@submission2)

    it "finds the first sample at B01 (because the A01 is blank", ->
      expect(@wellPlate.sampleAtCell("B01")).toEqual(@submission1.samples[0])

  describe "render()", ->
    beforeEach ->
      @wellPlate = new SangerSequencing.WellPlateBuilder
      @submission = { id: 542, samples: sampleList(8) }
      @wellPlate.addSubmission(@submission)

    it "has 96 cells", ->
      results = @wellPlate.render()
      expect(Object.keys(results).length).toEqual(96)

    it "renders odd rows first", ->
      results = @wellPlate.render()
      for expected in [
        ["A01", "reserved" ],
        ["B01", "Testing 0" ],
        ["C01", "Testing 1" ],
        ["D01", "Testing 2" ],
        ["E01", "Testing 3" ],
        ["F01", "Testing 4" ],
        ["G01", "Testing 5" ],
        ["H01", "Testing 6" ],
        ["A02", "reserved" ],
        ["B02", "" ],
        ["C02", "" ],
        ["D02", "" ],
        ["E02", "" ],
        ["F02", "" ],
        ["G02", "" ],
        ["H02", "" ],
        ["A03", "Testing 7" ],
        ["B03", "" ],
        ["C03", "" ],
        ["D03", "" ],
        ["E03", "" ],
        ["F03", "" ],
        ["G03", "" ],
        ["H03", "" ],
      ]
        well = expected[0]
        value = expected[1]
        expect(results[well].toString()).toEqual(value)
