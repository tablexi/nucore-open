#= require sanger_sequencing/print_warning
#= require helpers/jasmine-jquery

describe "Print Warning", ->

  it "does nothing without the right thing in place", ->
    warning = new PrintWarning
    spyOn(warning, "listen")
    expect(warning.shouldWarn()).toBeFalsy()
    warning.initListener()
    expect(warning.listen).not.toHaveBeenCalled()

  it "warns when the right elements are in place", ->
    warning = new PrintWarning
    spyOn(warning, "listen")
    setFixtures($("<h2>").addClass("js--print-warning"))
    expect(warning.shouldWarn()).toBeTruthy()
    warning.initListener()
    expect(warning.listen).toHaveBeenCalled()
