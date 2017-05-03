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
