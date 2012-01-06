require 'spec_helper'
require 'controller_spec_helper'

describe StatementsController do
  
  before(:all) do
    create_users
  end
  
  before(:each) do
    @authable = create_nufs_account_with_owner
  end
 
  context "index" do
    before :each do
      @method=:get
      @action=:index
      @params = { :account_id => @authable.id }
    end
    
    it_should_require_login
    
    it_should_deny_all [:guest, :purchaser]
    
    it_should_allow_all [:admin, :owner]  do
      response.should be_success
    end
    
  end
end
