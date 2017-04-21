#= require jquery
#= require helpers/jasmine-jquery

describe "Responsive table support", ->

  beforeEach ->
    window.IS_RESPONSIVE = true
    loadFixtures("normal_table.html")

  it "ignores a normal table", ->
    responsiveTable = new ResponsiveTable
    responsiveTable.respond()
    expect($(".table")).not.toContainElement(".responsive-header")

  it "responds to a responsive table if reponsive", ->
    $(".table").addClass("js--responsive_table")
    responsiveTable = new ResponsiveTable
    responsiveTable.respond()
    expect($("td .responsive-header").size()).toEqual(2)
    expect($("td .responsive-header").eq(0).text()).toEqual("Invoice Number")
    expect($("td .responsive-header").eq(1).text()).toEqual("Facility")

  it "ignores a table if the global variable is false", ->
    window.IS_RESPONSIVE = false
    $(".table").addClass("js--responsive_table")
    responsiveTable = new ResponsiveTable
    responsiveTable.respond()
    expect($(".table")).not.toContainElement(".responsive-header")
