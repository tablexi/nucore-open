require 'spec_helper'; require 'controller_spec_helper'

describe UsersController do
  integrate_views

  it "should route" do
    params_from(:get, "/facilities/url_name/users/new_search").should == {:controller => 'users', :action => 'new_search', :facility_id => 'url_name'}
    params_from(:post, "/facilities/url_name/users").should == {:controller => 'users', :action => 'create', :facility_id => 'url_name'}
  end

  before(:all) { create_users }

  before(:each) do
    @authable = Factory.create(:facility)
  end


  context "create" do

    it "should create a user" do
      @controller.stubs(:current_user).returns(@admin)
      @controller.stubs(:session_user).returns(@admin)
      @user_role = Hash[:group_name => 'Facility Director']
      sign_in @staff
      @user_params = Hash[:username => 'biggy_director', :first_name => "Biggy", :last_name => "Director", :email => 'bigd@nucore.com']
      post :create, :facility_id => @authable.url_name, :user_role => @user_role, :user => @user_params
      assigns[:current_facility].should == @authable
      # The assert below is valid, but it often (not always!) fails with
      # "OCIError: ORA-29275: partial multibyte character: select encrypt_password('OrXSmeAn') from dual",
      # which comes from Pers::Person#encrypt_password in the bcsec gem. That makes the test unreliable
      #assert_redirected_to facility_users_url
    end

  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
      @params={ :facility_id => @authable.url_name }
    end

    it_should_allow_operators_only do
      response.should be_success
      response.should render_template('users/index.html.haml')
    end

  end

end