require 'spec_helper'

describe TransactionHistoryController do
  before :each do
    @controller = TransactionHistoryController.new
    @facility = Factory.create(:facility, :url_name => "ffw")
    @facility2 = Factory.create(:facility, :url_name => "ttw")
    @facility3 = Factory.create(:facility, :url_name => "ibcflow")
  end
  
end
