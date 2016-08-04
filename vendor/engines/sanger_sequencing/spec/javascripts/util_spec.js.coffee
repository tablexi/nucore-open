#= require sanger_sequencing/util

describe "SangerSequencing.Util", ->
  beforeEach ->
    @util = SangerSequencing.Util

  describe "flattenArray", ->
    it "flattens a 2d array", ->
      array = [[1, 2], [3, 4], [5, 6]]
      expect(@util.flattenArray(array)).toEqual(
        [1, 2, 3, 4, 5, 6])

    it "leaves a 1d array alone", ->
      array = [1, 2, 3, 4, 5, 6]
      expect(@util.flattenArray(array)).toEqual(
        [1, 2, 3, 4, 5, 6])

    it "handles a mix of single elements and multi elements", ->
      array = [1, [2, 3], [4, 5, 6]]
      expect(@util.flattenArray(array)).toEqual(
        [1, 2, 3, 4, 5, 6])

    it "handles an empty array", ->
      array = []
      expect(@util.flattenArray(array)).toEqual([])

    it "only flattens a single level", ->
      array = [1, [2, [3, 4]], [[5, 6]]]
      expect(@util.flattenArray(array)).toEqual(
        [1, 2, [3, 4], [5, 6]])
