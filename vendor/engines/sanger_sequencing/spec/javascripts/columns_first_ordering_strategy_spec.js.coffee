#= require sanger_sequencing/columns_first_ordering_strategy

describe "SangerSequencing.ColumnsFirstOrderingStrategy", ->
  beforeEach ->
    @strategy = new SangerSequencing.ColumnsFirstOrderingStrategy()

  it "orders with letters increasing first", ->
    expect(@strategy.fillOrder()[0..9]).toEqual(["A01", "B01", "C01", "D01", "E01",
      "F01", "G01", "H01", "A02", "B02"])
