#= require sanger_sequencing/rows_first_ordering_strategy

describe "SangerSequencing.RowsFirstOrderingStrategy", ->
  beforeEach ->
    @strategy = new SangerSequencing.RowsFirstOrderingStrategy()

  it "orders with numbers increasing first", ->
    expect(@strategy.fillOrder()[0..13]).toEqual(["A01", "A02", "A03", "A04", "A05",
      "A06", "A07", "A08", "A09", "A10", "A11", "A12", "B01", "B02"])
