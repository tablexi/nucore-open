require 'spec_helper'
require 'controller_spec_helper'

describe ProductAccessoriesController do
  render_views

  before(:all) { create_users }

  let(:instrument) { FactoryGirl.create(:setup_instrument) }
  let(:facility) { instrument.facility }
  let(:accessory) { FactoryGirl.create(:setup_item, :facility => facility) }
  let(:unchosen_accessory) { FactoryGirl.create(:setup_item, :facility => facility) }

  before :each do
    @authable = facility
    @params = { :facility_id => facility.url_name, :product_id => instrument.url_name }
  end

  describe 'index' do
    before :each do
      @method = :get
      @action = :index
    end

    it_should_allow_operators_only do
      # success!
    end

    context 'with an available accessory' do
      before :each do
        maybe_grant_always_sign_in :admin
        instrument.accessories << accessory
        unchosen_accessory # load
        do_request
      end

      it 'has the unchosen accessory in the list' do
        expect(assigns(:available_accessories)).to include(unchosen_accessory)
      end

      it 'excludes the already created accessory in the list' do
        expect(assigns(:available_accessories)).to_not include(accessory)
      end

      it 'does not include itself' do
        expect(assigns(:available_accessories)).to_not include(instrument)
      end
    end
  end

  describe 'create' do
    before :each do
      @method = :post
      @action = :create
    end

    it_should_allow_managers_and_senior_staff_only(:redirect) {}

    context 'success' do
      before :each do
        maybe_grant_always_sign_in :admin
        @params.merge! :product_accessory => { :accessory_id => accessory.id }
      end

      context 'default type' do
        before :each do
          expect(instrument.accessories).to be_empty
          do_request
        end

        it 'creates the new accessory' do
          expect(instrument.reload.accessories).to eq([accessory])
        end

        it 'the new accessory is quantity based' do
          expect(instrument.reload.product_accessories.first.scaling_type).to eq('quantity')
        end

        it 'redirects to index' do
          expect(response).to redirect_to(:action => :index)
        end
      end

      context 'auto scaled' do
        before :each do
          @params.deep_merge! :product_accessory => { :scaling_type => 'auto' }
          do_request
        end

        it 'creates the new accessory' do
          expect(instrument.reload.accessories).to eq([accessory])
        end

        it 'sets the new accessory as auto-scaled' do
          expect(instrument.reload.product_accessories.first.scaling_type).to eq('auto')
        end

        it 'redirects to index' do
          expect(response).to redirect_to(:action => :index)
        end
      end
    end
  end

  describe 'destroy' do
    before :each do
      instrument.accessories << accessory
      @method = :delete
      @action = :destroy
      @params.merge! :id => instrument.product_accessories.first.id
    end

    it_should_allow_managers_and_senior_staff_only(:redirect) {}

    context 'signed in' do
      before :each do
        maybe_grant_always_sign_in :admin
        do_request
      end

      it 'destroys the accessory' do
        expect(assigns(:product_accessory)).to be_destroyed
      end

      it 'redirects to index' do
        expect(response).to redirect_to(:action => :index)
      end
    end
  end
end
