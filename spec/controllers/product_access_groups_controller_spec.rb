require 'spec_helper'
require 'controller_spec_helper'

describe ProductAccessGroupsController do
  render_views
  before :all do
    create_users
  end

  before :each do
    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @instrument       = FactoryGirl.create(:instrument,
                                      :facility => @authable,
                                      :facility_account => @facility_account)
    @params={ :instrument_id => @instrument.url_name, :facility_id => @authable.url_name }
  end

  context 'index' do
    before :each do
      @level = FactoryGirl.create(:product_access_group, :product => @instrument)
      @level2 = FactoryGirl.create(:product_access_group, :product => @instrument)
      @instrument2 = FactoryGirl.create(:instrument,
                                      :facility => @authable,
                                      :facility_account => @facility_account)
      @level3 = FactoryGirl.create(:product_access_group, :product => @instrument2)

      @action = :index
      @method = :get
    end
    it_should_allow_operators_only :success, 'see index' do
      expect(assigns[:facility]).to eq(@authable)
      expect(assigns[:instrument]).to eq(@instrument)
      expect(assigns[:product_access_groups]).to eq([@level, @level2])
    end
  end

  context 'new' do
    before :each do
      @action = :new
      @method = :get
    end
    it_should_allow_managers_and_senior_staff_only :success, 'do new' do
      expect(assigns[:facility]).to eq(@authable)
      expect(assigns[:instrument]).to eq(@instrument)
      expect(assigns[:product_access_group]).to be_new_record
      expect(response).to render_template :new
    end
  end

  context 'create' do
    before :each do
      @action = :create
      @method = :post
    end
    context 'correct info' do
      before :each do
        @params.merge!({:product_access_group => FactoryGirl.attributes_for(:product_access_group)})
      end
      it_should_allow_managers_and_senior_staff_only :redirect, 'do create' do
        expect(assigns[:facility]).to eq(@authable)
        expect(assigns[:instrument]).to eq(@instrument)
        expect(assigns[:product_access_group]).not_to be_new_record
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(facility_instrument_product_access_groups_path(@authable, @instrument))
      end
    end
    context 'missing data' do
      before :each do
        @params.merge!({:product_access_group => FactoryGirl.attributes_for(:product_access_group, :name => '')})
      end
      it_should_allow_managers_and_senior_staff_only :success, 'do create' do
        expect(assigns[:facility]).to eq(@authable)
        expect(assigns[:instrument]).to eq(@instrument)
        expect(assigns[:product_access_group]).to be_new_record
        expect(assigns[:product_access_group].errors).not_to be_empty
        expect(response).to render_template :new
      end
    end
  end

  context 'edit' do
    before :each do
      @action = :edit
      @method = :get
      @product_access_group = FactoryGirl.create(:product_access_group, :product_id => @instrument.id)
      @params.merge!({:id => @product_access_group.id})
    end
    it_should_allow_managers_and_senior_staff_only :success, 'do edit' do
      expect(assigns[:facility]).to eq(@authable)
      expect(assigns[:instrument]).to eq(@instrument)
      expect(assigns[:product_access_group]).to eq(@product_access_group)
      expect(response).to render_template :edit
    end
  end
  context 'update' do
    before :each do
      @action = :update
      @method = :post
      @product_access_group = FactoryGirl.create(:product_access_group, :product_id => @instrument.id)
      @params.merge!({:id => @product_access_group.id})
    end
    context 'correct info' do
      before :each do
        @params.merge!({:product_access_group => {:name => 'new name'}})
      end
      it_should_allow_managers_and_senior_staff_only :redirect, 'do update' do
        expect(assigns[:facility]).to eq(@authable)
        expect(assigns[:instrument]).to eq(@instrument)
        expect(assigns[:product_access_group]).to eq(@product_access_group)
        expect(assigns[:product_access_group].name).to eq('new name')
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(facility_instrument_product_access_groups_path(@authable, @instrument))
      end
    end
    context 'missing data' do
      before :each do
        @params.merge!({:product_access_group => {:name => ''}})
      end
      it_should_allow_managers_and_senior_staff_only :success, 'do update' do
        expect(assigns[:facility]).to eq(@authable)
        expect(assigns[:instrument]).to eq(@instrument)
        expect(assigns[:product_access_group]).to eq(@product_access_group)
        expect(assigns[:product_access_group].errors).not_to be_empty
        expect(response).to render_template :edit
      end
    end
  end

  context 'destroy' do
    before :each do
      @method=:delete
      @action=:destroy
      @product_access_group = FactoryGirl.create(:product_access_group, :product => @instrument)
      @params.merge!({:id => @product_access_group.id})
    end
    it_should_allow_managers_and_senior_staff_only :redirect, 'do delete' do
      expect(assigns[:product_access_group]).to be_destroyed
      expect(flash[:notice]).not_to be_nil
      expect(response).to redirect_to(facility_instrument_product_access_groups_path(@authable, @instrument))
    end
  end

end
