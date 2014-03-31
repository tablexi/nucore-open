require 'spec_helper'; require 'controller_spec_helper'

describe SurveysController do
  render_views

  before(:all) { create_users }

  let(:authable) { create :facility }
  let(:facility_account) { authable.facility_accounts.create attributes_for(:facility_account) }
  let(:order_status) { create :order_status }
  let(:service) { authable.services.create attributes_for(:service, initial_order_status_id: order_status.id, facility_account_id: facility_account.id) }
  let(:external_service) { UrlService.create! location: 'http://ext.service.com' }
  let(:external_service_passer) { ExternalServicePasser.create! passer: service, external_service: external_service }
  let(:external_service2) { UrlService.create! location: 'http://ext.service2.com' }
  let(:external_service_passer2) { ExternalServicePasser.create! passer: service, external_service: external_service2 }

  before(:each) do
    @request.env['HTTP_REFERER'] = "http://nucore.com/facilities/#{authable.url_name}/services/#{service.url_name}"
    @params = {
      facility_id: authable.url_name,
      service_id: service.url_name,
      external_service_passer_id: external_service_passer.id
    }
  end


  context 'deactivate' do

    before(:each) do
      @method = :put
      @action = :deactivate
    end

    it_should_allow_managers_only :redirect do
      test_change_state(false)
    end

  end


  context "activate" do

    before(:each) do
      @method = :put
      @action = :activate
    end

    it_should_allow_managers_only :redirect do
      test_change_state(true)
    end

  end


  context "complete" do
    let(:survey_url) { 'http://this.survey.url' }


    before(:each) do
      @method = :get
      @action = :complete
      create_order_detail
      @params[:external_service_passer_id] = nil
      @params[:external_service_id] = external_service.id
      @params[:receiver_id] = @order_detail.id
      @params[:survey_url] = survey_url
      @params[:referer] = 'http://some.web.address'
      expect(ExternalServiceReceiver.count).to eq 0
    end

    it_should_require_login

    it_should_allow_all facility_users do
      expect(ExternalServiceReceiver.count).to eq 1
      esr = ExternalServiceReceiver.first
      expect(esr.receiver).to eq @order_detail
      expect(esr.external_service).to eq external_service
      expect(esr.response_data).to include survey_url
      should redirect_to @params[:referer]
    end

    context 'merge orders' do
      before :each do
        @clone = @order.dup
        assert @clone.save
        @order.update_attribute :merge_with_order_id, @clone.id
        expect(@order).to be_to_be_merged
      end

      it_should_allow :director, 'to complete survey on merge order' do
        expect(@order_detail.reload.order).to eq @clone
        assert_raises(ActiveRecord::RecordNotFound) { @order.reload }
      end

    end
  end


  private

  def test_change_state(active)
    expect(assigns[:service]).to eq service
    expect(external_service_passer.reload.active).to eq active
    expect(external_service_passer2.reload.active).to be_false
    should set_the_flash
    should redirect_to @request.env['HTTP_REFERER']

    @params[:external_service_passer_id] = external_service_passer2.id
    do_request
    expect(external_service_passer.reload.active).to be_false
    expect(external_service_passer2.reload.active).to eq active
  end


  def create_order_detail
    @product = create(:item,
      facility_account: facility_account,
      facility: authable
    )
    @account = create_nufs_account_with_owner
    @order = create(:order,
      facility: authable,
      user: @director,
      created_by: @director.id,
      account: @account,
      ordered_at: Time.zone.now
    )
    @price_group = FactoryGirl.create(:price_group, facility: authable)
    @price_policy = FactoryGirl.create(:item_price_policy, product: @product, price_group: @price_group)
    @order_detail = FactoryGirl.create(:order_detail, order: @order, product: @product, price_policy: @price_policy)
  end

end
