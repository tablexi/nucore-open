require 'spec_helper'; require 'controller_spec_helper'

describe FacilityOrderDetailsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
    @facility_account=FactoryGirl.create(:facility_account, :facility => @authable)
    @product=FactoryGirl.create(:item,
      :facility_account => @facility_account,
      :facility => @authable
    )
    @account=create_nufs_account_with_owner :director
    @order=FactoryGirl.create(:order,
      :facility => @authable,
      :user => @director,
      :created_by => @director.id,
      :account => @account,
      :ordered_at => Time.zone.now,
      :state => 'purchased'
    )
    @price_group=FactoryGirl.create(:price_group, :facility => @authable)
    @price_policy=FactoryGirl.create(:item_price_policy, :product => @product, :price_group => @price_group)
    @order_detail=FactoryGirl.create(:order_detail, :order => @order, :product => @product, :price_policy => @price_policy)
    @order_detail.set_default_status!
    @params={ :facility_id => @authable.url_name, :order_id => @order.id, :id => @order_detail.id }
  end

  context 'destroy' do
    before :each do
      @method=:delete
      @action=:destroy
    end

    it_should_allow_operators_only :redirect do
      expect(flash[:notice]).to be_present
      expect(@order_detail.reload).not_to be_frozen
      assert_redirected_to facility_order_path(@authable, @order)
    end

    context 'merge order' do
      before :each do
        @clone=@order.dup
        assert @clone.save
        @order.update_attribute :merge_with_order_id, @clone.id
      end

      it_should_allow :director, 'to destroy a detail that is part of a merge order' do
        assert_raises(ActiveRecord::RecordNotFound) { OrderDetail.find @order_detail.id }
        expect(flash[:notice]).to be_present
        assert_redirected_to facility_order_path(@authable, @clone)
      end
    end
  end

  def prepare_reservation
    @order_detail.update_attributes(:price_policy => nil)
    @instrument = FactoryGirl.create(:instrument, :facility => @authable,
      :facility_account => @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account)))
    @instrument_price_policy=FactoryGirl.create(:instrument_price_policy,
                                            :product => @instrument,
                                            :price_group => @price_group,
                                            :usage_rate => 10,
                                            :usage_subsidy => 0)
    expect(@instrument_price_policy).to be_persisted
    allow_any_instance_of(Instrument).to receive(:cheapest_price_policy).and_return(@instrument_price_policy)
    @reservation = place_reservation @authable, @order_detail, 1.day.ago
    @order_detail.backdate_to_complete! @reservation.reserve_end_at
  end
end
