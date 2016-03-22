require "rails_helper"
require "controller_spec_helper"

RSpec.describe AffiliatesController do
  render_views

  before(:all) { create_users }
  before(:each) { @authable = create(:facility) }

  context "index" do

    before :each do
      @method = :get
      @action = :index
    end

    it_should_allow_admin_only do
      is_expected.to render_template :index
    end
  end

  context "new" do

    before :each do
      @method = :get
      @action = :new
    end

    it_should_allow_admin_only do
      expect(assigns(:affiliate)).to be_kind_of Affiliate
      expect(assigns(:affiliate)).to be_new_record
      is_expected.to render_template :new
    end
  end

  context "create" do

    before :each do
      @method = :post
      @action = :create
      @params = { affiliate: { name: "Chik-Fil-A" } }
    end

    it_should_allow_admin_only :redirect do
      is_expected.to set_flash
      expect(assigns(:affiliate)).not_to be_new_record
      expect(assigns(:affiliate).name).to eq(@params[:affiliate][:name])
      assert_redirected_to affiliates_path
    end

    it "should fail gracefully if no attributes posted" do
      no_attrs_test { assert_redirected_to new_affiliate_path }
    end

    it("should fail gracefully if bad attributes posted") do
      bad_attrs_test(:new) { expect(assigns(:affiliate)).to be_new_record }
    end
  end

  context "with id param" do

    before :each do
      @affiliate = Affiliate.find_or_create_by_name("CTA")
      @params = { id: @affiliate.id }
    end

    context "edit" do

      before :each do
        @method = :get
        @action = :edit
      end

      it_should_allow_admin_only do
        expect(assigns(:affiliate)).to eq(@affiliate)
        is_expected.to render_template :edit
      end

      it("should fail gracefully if bad id given") { bad_id_test }
    end

    context "update" do

      before :each do
        @method = :put
        @action = :update
        @params.merge!(affiliate: { name: "fugly.com" })
      end

      it_should_allow_admin_only :redirect do
        is_expected.to set_flash
        expect(assigns(:affiliate).name).to eq(@params[:affiliate][:name])
        assert_redirected_to affiliates_path
      end

      it("should fail gracefully if bad id given") { bad_id_test }

      it("should fail gracefully if bad attributes posted") { bad_attrs_test :edit }

      it "should fail gracefully if no attributes posted" do
        no_attrs_test { is_expected.to render_template :edit }
      end
    end

    context "destroy" do

      before :each do
        @method = :delete
        @action = :destroy
      end

      it_should_allow_admin_only :redirect do
        should_be_destroyed @affiliate
        is_expected.to set_flash
        assert_redirected_to affiliates_path
      end

      it("should fail gracefully if bad id given") { bad_id_test }
    end

  end

  def bad_id_test
    @params[:id] = 98_765_423_456
    maybe_grant_always_sign_in :admin
    do_request
    is_expected.to set_flash
    assert_redirected_to affiliates_path
  end

  def bad_attrs_test(template)
    @params[:affiliate][:name] = nil
    maybe_grant_always_sign_in :admin
    do_request
    yield if block_given?
    expect(assigns(:affiliate).name).to be_nil
    is_expected.to render_template template
  end

  def no_attrs_test
    @params[:affiliate] = nil
    maybe_grant_always_sign_in :admin
    do_request
    expect(flash[:error]).to be_present
    yield if block_given?
  end
end
