require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the TransactionHistoryHelper. For example:
describe TransactionHistoryHelper do
  
  describe "single_account?" do
    it "should return true for one account" do
      @accounts = ["1"]      
      single_account?.should be_true
    end

    it "should return false for zero accounts" do
      @accounts = []
      single_account?.should be_false
    end

    it "should return false for 2 or more accounts" do
      arr = ["1"]
      (2..5).each do |i|
        arr << i.to_s
        @accounts = arr
        single_account?.should be_false
      end
    end

    it "should return false if there is no account key" do
      @accounts = nil
      single_account?.should be_false
    end
    
  end
end
