#= require jquery
#= require helpers/jasmine-jquery

describe "Responsive table support", ->

  it "ignores a normal table", ->
    loadFixtures("normal_table.html")
    responsiveTable = new ResponsiveTable
    responsiveTable.respond()
    expect($(".table")).not.toContainElement(".responsive-header")

  it "responds to a responsive table if reponsive", ->
    loadFixtures("normal_table.html")
    $(".table").addClass("js--responsive_table")
    responsiveTable = new ResponsiveTable
    responsiveTable.respond()
    expect($("td .responsive-header").size()).toEqual(2)
    expect($("td .responsive-header").eq(0).text()).toEqual("Invoice Number")
    expect($("td .responsive-header").eq(1).text()).toEqual("Facility")
