#= require jquery
#= require helpers/jasmine-jquery

describe "Responsive table support", ->

  beforeEach ->
    window.IS_RESPONSIVE = true
    loadFixtures("normal_table.html")

  it "ignores a normal table", ->
    ResponsiveTable.respond()
    expect($(".table")).not.toContainElement(".responsive-header")

  it "responds to a responsive table if reponsive", ->
    $(".table").addClass("js--responsive_table")
    ResponsiveTable.respond()
    expect($("td .responsive-header").size()).toEqual(4)
    expect($("td .responsive-header").eq(0).text()).toEqual("Invoice #")
    expect($("td .responsive-header").eq(1).text()).toEqual("Facility")
    expect($("td .responsive-header").eq(2).text()).toEqual("Invoice #")
    expect($("td .responsive-header").eq(3).text()).toEqual("Facility")

  it "ignores a table if the global variable is false", ->
    window.IS_RESPONSIVE = false
    $(".table").addClass("js--responsive_table")
    ResponsiveTable.respond()
    expect($(".table")).not.toContainElement(".responsive-header")

  it "inserts a space if the table cell is empty, for spacing", ->
    $(".table").addClass("js--responsive_table")
    expected = $("td").eq(2).clone().append("Invoice #&nbsp;").text()
    ResponsiveTable.respond()
    expect($("td").eq(2).text()).toEqual(expected)
    expect($("td").eq(3).text()).toEqual("FacilitySmall Hadron Collider")

  describe "when there is a sub-table", ->
    beforeEach ->
      loadFixtures("nested_table.html")
      $(".table").addClass("js--responsive_table")
      ResponsiveTable.respond()

    it "sets the outer table headers", ->
      $outerTableHeaders = $("#outer-table > tbody > tr > td > .responsive-header")
      expect($outerTableHeaders.size()).toEqual(4)
      expect($outerTableHeaders.eq(0).text()).toEqual("Invoice #")
      expect($outerTableHeaders.eq(1).text()).toEqual("Facility")
      expect($outerTableHeaders.eq(2).text()).toEqual("Invoice #")
      expect($outerTableHeaders.eq(3).text()).toEqual("Facility")

    it "sets the inner table headers", ->
      $innerTableHeaders = $("#inner-table .responsive-header")
      expect($innerTableHeaders.size()).toEqual(4)
      expect($innerTableHeaders.eq(0).text()).toEqual("Inner Header 1")
      expect($innerTableHeaders.eq(1).text()).toEqual("Inner Header 2")
      expect($innerTableHeaders.eq(2).text()).toEqual("Inner Header 1")
      expect($innerTableHeaders.eq(3).text()).toEqual("Inner Header 2")
