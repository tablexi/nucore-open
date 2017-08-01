require "rails_helper"
require "controller_spec_helper"

RSpec.describe ProductAccessoriesController do
  render_views

  before(:all) { create_users }

  let(:instrument) { FactoryGirl.create(:setup_instrument) }
  let(:facility) { instrument.facility }
  let(:accessory) { FactoryGirl.create(:setup_item, facility: facility) }
  let(:timed_service) { FactoryGirl.create(:setup_timed_service, facility: facility) }

  before :each do
    @authable = facility
    @params = { facility_id: facility.url_name, product_id: instrument.url_name }
  end

  describe "index" do
    let!(:unchosen_accessory) { FactoryGirl.create(:setup_item, facility: facility) }
    let!(:bundle) do
      FactoryGirl.create(:bundle, facility: facility)
    end

    before :each do
      @method = :get
      @action = :index
    end

    it_should_allow_operators_only do
      # success!
    end

    context "with an available accessory" do
      before :each do
        maybe_grant_always_sign_in :admin
        instrument.accessories << accessory
        do_request
      end

      it "has the unchosen accessory in the list" do
        expect(assigns(:available_accessories)).to include(unchosen_accessory)
      end

      it "excludes the already created accessory in the list" do
        expect(assigns(:available_accessories)).not_to include(accessory)
      end

      it "does not include itself" do
        expect(assigns(:available_accessories)).not_to include(instrument)
      end

      it "does not include the bundle" do
        expect(assigns(:available_accessories)).not_to include(bundle)
      end
    end

    it "only includes active accessories" do
      maybe_grant_always_sign_in :admin
      instrument.accessories << accessory
      ProductAccessory.first.soft_delete
      instrument.accessories << unchosen_accessory
      do_request
      expect(assigns(:product_accessories)).not_to include(accessory)
    end
  end

  describe "create" do
    let(:scaling_type) { "quantity" }

    before do
      @method = :post
      @action = :create
      @params.merge! product_accessory: { accessory_id: accessory.id, scaling_type: scaling_type }
    end

    it_should_allow_managers_and_senior_staff_only(:redirect) {}

    context "success" do
      before do
        maybe_grant_always_sign_in :admin
      end

      context "with quantity-based accessory" do

        before do
          expect(instrument.accessories).to be_empty
          do_request
        end

        it "creates the new accessory" do
          expect(instrument.reload.accessories).to eq([accessory])
        end

        it "the new accessory is quantity based" do
          expect(instrument.reload.product_accessories.first.scaling_type).to eq("quantity")
        end

        it "redirects to index" do
          expect(response).to redirect_to(action: :index)
        end
      end

      context "with time-based accessory" do
        let(:accessory) { timed_service }
        let(:scaling_type) { "auto" }

        before do
          do_request
        end

        it "creates the new accessory" do
          expect(instrument.reload.accessories).to eq([timed_service])
        end

        it "sets the new accessory as auto-scaled" do
          expect(instrument.reload.product_accessories.first.scaling_type).to eq("auto")
        end

        it "redirects to index" do
          expect(response).to redirect_to(action: :index)
        end
      end
    end
  end

  describe "destroy" do
    before :each do
      instrument.accessories << accessory
      @method = :delete
      @action = :destroy
      @params.merge! id: instrument.product_accessories.first.id
    end

    it_should_allow_managers_and_senior_staff_only(:redirect) {}

    context "signed in" do
      before :each do
        maybe_grant_always_sign_in :admin
        do_request
      end

      it "soft deletes the accessory" do
        expect(assigns(:product_accessory)).to be_deleted
      end

      it "redirects to index" do
        expect(response).to redirect_to(action: :index)
      end
    end
  end
end
