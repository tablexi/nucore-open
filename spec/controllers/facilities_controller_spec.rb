require 'spec_helper'; require 'controller_spec_helper'

describe FacilitiesController do
  integrate_views

  it "should route" do
    params_from(:get, "/facilities").should == {:controller => 'facilities', :action => 'index'}
    params_from(:get, "/facilities/url_name").should == {:controller => 'facilities', :action => 'show', :id => 'url_name'}
    params_from(:get, "/facilities/url_name/manage").should == {:controller => 'facilities', :action => 'manage', :id => 'url_name'}
  end

  before(:all) { create_users }

  before(:each) do
    @authable = Factory.create(:facility)
  end


  context "new" do

    before(:each) do
      @method=:get
      @action=:new
    end

    it_should_require_login

    it_should_deny :director

    it_should_allow :admin do
      @controller.expects(:init_current_facility).never
      do_request
      response.should be_success
      response.should render_template('facilities/new.html.haml')
    end

  end


  context "create" do

    before(:each) do
      @method=:post
      @action=:create
      @params={
        :facility => {
          :name => "A New Facility", :abbreviation => "anf", :description => "A boring description",
          :is_active => 1, :url_name => 'anf', :short_description => 'A short boring desc'
        }
      }
    end

    it_should_require_login
  
    it_should_deny_all [ :guest, :director ]

    it_should_allow :admin do
      assigns[:facility].should be_valid
      response.should redirect_to "/facilities/anf/manage"
    end

  end


  context "index" do

    before(:each) do
      @method=:get
      @action=:index
    end
    
    it_should_allow_all [ :admin, :guest ] do
      assigns[:facilities].should == [@authable]
      response.should be_success
      response.should render_template('facilities/index.html.haml')
    end

  end


  context "manage" do

    before(:each) do
      @method=:get
      @action=:manage
      @params={ :facility_id => @authable.url_name, :id => @authable.url_name }
    end

    it_should_require_login
  
    it_should_deny :guest
  
    it_should_allow :director do
      response.should be_success
      response.should render_template('facilities/manage.html.haml')
    end

  end


  context "show" do

    before(:each) do
      @method=:get
      @action=:show
      @params={ :id => @authable.url_name }
    end

    it_should_allow_all ([ :guest ] + facility_operators) do
      @controller.current_facility.should == @authable
      response.should be_success
      response.should render_template('facilities/show.html.haml')
      assert_nav_tabs
    end
    
  end


  context "list" do

    before(:each) do
      @method=:get
      @action=:list
    end

    it_should_require_login

    it_should_deny :guest

    context "as facility operators" do

      before(:each) do
        @controller.stubs(:current_facility).returns(@authable)
        @controller.expects(:init_current_facility).never
      end

      it_should_allow_all facility_operators do
        assigns(:manageable_facilities).should_not be_nil
        assigns(:facilities).should == [@authable]
        response.should be_success
        response.should render_template('facilities/list.html.haml')
        assert_nav_tabs
        response.should have_tag('li.right') do
          with_tag 'a', 'Manage Facilities'
        end
      end
    end

    context "as administrator" do

      before(:each) do
        @facility2 = Factory.create(:facility)
        @controller.stubs(:current_facility).returns(@authable)
      end
  
      it_should_allow :admin do
        assigns[:manageable_facilities].should == []
        assigns[:facilities].should == [@authable, @facility2]
        response.should be_success
        response.should render_template('facilities/list.html.haml')
        # should have 'add facility' link
        response.should have_tag('a', 'Add Facility') 
        assert_nav_tabs
        # should have 'manage facilities' nav bar
        response.should have_tag('li.right') do
          with_tag 'a', 'Manage Facilities'
        end
        response.should_not have_tag('li.right > ul') do
          with_tag 'li', @authable.name
        end
      end
    end

  end


  def assert_nav_tabs
    response.should have_tag('ul > li') do
      with_tag('a', :text => 'Home')
      with_tag('a', :text => 'My Orders')
      without_tag('a', :text => 'Orders')
      without_tag('a', :text => 'Invoices')
      without_tag('a', :text => 'Products')
      without_tag('a', :text => 'Reports')
      without_tag('a', :text => 'Admin')
    end
  end
end
