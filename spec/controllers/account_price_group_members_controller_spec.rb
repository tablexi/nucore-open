require 'spec_helper'; require 'controller_spec_helper'

describe AccountPriceGroupMembersController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryGirl.create(:facility)
    @price_group = @authable.price_groups.create(FactoryGirl.attributes_for(:price_group))
  end

  # allow admins
  # allow directors
  # allow staff
  # deny guests
  
  context "new" do

    before :each do
      @method=:get
      @action=:new
      @params={ :facility_id => @authable.url_name, :price_group_id => @price_group.id }
    end

    it_should_require_login

    it_should_deny :guest

    it_should_allow_all facility_operators do
      should render_template('new')
      should assign_to(:price_group).with_kind_of(PriceGroup)
      should assign_to(:account_price_group_member).with_kind_of(AccountPriceGroupMember)
      assigns(:account_price_group_member).should be_new_record
    end
  end


  context "create" do

    before :each do
      @method=:post
      @action=:create
      account=create_nufs_account_with_owner
      @params={ :facility_id => @authable.url_name, :price_group_id => @price_group.id, :account_id => account.id }
    end

    it_should_require_login

    it_should_deny :guest

    it_should_allow_all facility_operators do
      should assign_to(:price_group).with_kind_of(PriceGroup)
      should assign_to(:account).with_kind_of(Account)
      should assign_to(:account_price_group_member).with_kind_of(AccountPriceGroupMember)
      should set_the_flash
      assert_redirected_to([@authable, @price_group])
    end
  end


  context "destroy" do

    before(:each) do
      @method=:delete
      @action=:destroy
      @account=create_nufs_account_with_owner
      @account_price_group_member=AccountPriceGroupMember.create!(:price_group => @price_group, :account => @account)
      @params={ :facility_id => @authable.url_name, :price_group_id => @price_group.id, :id => @account_price_group_member.id }
    end

    it_should_require_login

    it_should_deny :guest

    it_should_allow_all facility_operators do
      should assign_to(:price_group).with_kind_of(PriceGroup)
      should assign_to(:account_price_group_member).with_kind_of(AccountPriceGroupMember)
      assigns(:account_price_group_member).should be_frozen
      should set_the_flash
      assert_redirected_to(facility_price_group_url(@authable, @price_group))
    end

  end


  context "search_results" do

    before :each do
      @method=:get
      @action=:search_results
      @params={ :facility_id => @authable.url_name, :price_group_id => @price_group.id, :search_term => '' }
    end

    it_should_require_login

    it_should_deny :guest

    it_should_allow_all facility_operators do
      # TODO: test GET with valid search term
      should assign_to(:limit).with_kind_of(Fixnum)
      should assign_to(:price_group).with_kind_of(PriceGroup)
      should render_template('search_results')
    end
    
  end

end
