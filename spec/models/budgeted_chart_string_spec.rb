require 'spec_helper'

describe BudgetedChartString do

  it "should require fund" do
    should validate_presence_of(:fund)
  end

  it "should require dept" do
    should validate_presence_of(:dept)
  end

  it "should require starts_at" do
    should validate_presence_of(:starts_at)
  end

  it "should require expires_at" do
    should validate_presence_of(:expires_at)
  end

  it "should parse file" do
    filename = "#{RAILS_ROOT}/spec/files/budgeted_chart_strings1.txt"
    BudgetedChartString.delete_all
    BudgetedChartString.import(filename)
    # should have 2 records plus the 4 test records
    assert_equal 6, BudgetedChartString.count
    # should properly parse account fields and dates
    bcs1 = (BudgetedChartString.all)[4]
    bcs2 = BudgetedChartString.last
    assert_equal "20080910", bcs1.starts_at.strftime("%Y%m%d")
    assert_equal "20090831", bcs1.expires_at.strftime("%Y%m%d")
    assert_equal "191", bcs1.fund
    assert_equal "1000000", bcs1.dept
    assert_equal "20090901", bcs2.starts_at.strftime("%Y%m%d")
    assert_equal "20100831", bcs2.expires_at.strftime("%Y%m%d")
    assert_equal "732", bcs2.fund
    assert_equal "2105600", bcs2.dept
  end

end