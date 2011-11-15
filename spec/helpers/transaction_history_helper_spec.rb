require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the TransactionHistoryHelper. For example:
#
# describe TransactionHistoryHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end
describe TransactionHistoryHelper do
  describe "single_account?" do
    it "should return true for one account" do
      @search_fields = { :accounts => ["12"] }
      single_account?.should be_true
    end

    it "should return false for zero accounts" do
      @search_fields = { :accounts => [] }
      single_account?.should be_false
    end

    it "should return false for 2 or more accounts" do
      arr = ["1"]
      (2..5).each do |i|
        arr << i.to_s
        @search_fields = { :accounts => arr }
        single_account?.should be_false
      end
    end

    it "should return false if there is no account key" do
      @search_fields = {}
      single_account?.should be_false
    end
    
  end
end
