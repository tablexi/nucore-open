require "rails_helper"

RSpec.describe BulkEmailSearcher do
  shared_examples_for "active/inactive users" do
    describe "with an active user" do
      it "returns the user" do
        expect(users).to include(user)
      end
    end

    describe "with an inactive user" do
      before { user.deactivate }

      it "does not include the user" do
        expect(users).not_to include(user)
      end
    end
  end

  let(:searcher) { described_class.new(params) }

  let(:users) { searcher.do_search }
  let(:owner) { FactoryGirl.create(:user) }
  let(:purchaser)  { FactoryGirl.create(:user) }
  let(:purchaser2) { FactoryGirl.create(:user) }
  let(:purchaser3) { FactoryGirl.create(:user) }

  let(:facility) { FactoryGirl.create(:facility) }
  let(:facility_account) { FactoryGirl.create(:facility_account, facility: facility) }

  let(:product) { FactoryGirl.create(:item, facility_account: facility_account, facility: facility) }
  let(:product2) { FactoryGirl.create(:item, facility_account: facility_account, facility: facility) }
  let(:product3) { FactoryGirl.create(:item, facility_account: facility_account, facility: facility) }

  let(:account) { FactoryGirl.create(:nufs_account, account_users_attributes: [FactoryGirl.attributes_for(:account_user, user: owner)]) }

  let(:params) { { search_type: :customers, facility_id: facility.id } }

  before :each do
    ignore_order_detail_account_validations
  end

  context "search customers filtered by ordered dates" do
    before :each do
      @od_yesterday = place_product_order(purchaser, facility, product, account)
      @od_yesterday.order.update_attributes(ordered_at: (Time.zone.now - 1.day))

      @od_tomorrow = place_product_order(purchaser2, facility, product2, account)
      @od_tomorrow.order.update_attributes(ordered_at: (Time.zone.now + 1.day))

      @od_today = place_product_order(purchaser3, facility, product, account)
    end

    it_behaves_like "active/inactive users" do
      let(:user) { purchaser }
    end

    it "returns only the one today and the one tomorrow" do
      params[:start_date] = Time.zone.now
      expect(users).to contain_all [purchaser3, purchaser2]
      expect(searcher.order_details).to contain_all [@od_today, @od_tomorrow]
    end

    it "returns only the one today and the one yesterday" do
      params[:end_date] = Time.zone.now
      expect(users).to contain_all [purchaser3, purchaser]
      expect(searcher.order_details).to contain_all [@od_yesterday, @od_today]
    end

    it "returns only the one from today" do
      params[:start_date] = Time.zone.now
      params[:end_date] = Time.zone.now
      expect(users).to eq([purchaser3])
      expect(searcher.order_details).to eq([@od_today])
    end
  end

  context "search customers filtered by reserved dates" do
    before :each do
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument = FactoryGirl.create(:instrument,
                                       facility: facility,
                                       facility_account: facility_account,
                                       min_reserve_mins: 60,
                                       max_reserve_mins: 60)

      @reservation_yesterday = place_reservation_for_instrument(purchaser, @instrument, account, Time.zone.now - 1.day)
      @reservation_tomorrow = place_reservation_for_instrument(purchaser2, @instrument, account, Time.zone.now + 1.day)
      @reservation_today = place_reservation_for_instrument(purchaser3, @instrument, account, Time.zone.now)
    end

    it_behaves_like "active/inactive users" do
      let(:user) { purchaser }
    end

    it "returns only the one today and the one tomorrow" do
      params[:start_date] = Time.zone.now
      expect(users).to contain_all [purchaser3, purchaser2]
      expect(searcher.order_details).to contain_all [@reservation_today.order_detail, @reservation_tomorrow.order_detail]
    end

    it "returns only the one today and the one yesterday" do
      params[:end_date] = Time.zone.now
      expect(users).to contain_all [purchaser3, purchaser]
      expect(searcher.order_details).to contain_all [@reservation_yesterday.order_detail, @reservation_today.order_detail]
    end

    it "returns only the one from today" do
      params[:start_date] = Time.zone.now
      params[:end_date] = Time.zone.now
      expect(users).to eq([purchaser3])
      expect(searcher.order_details).to eq([@reservation_today.order_detail])
    end
  end

  context "search customers filtered by products" do
    before :each do
      @od1 = place_product_order(purchaser, facility, product, account)
      @od2 = place_product_order(purchaser2, facility, product2, account)
      @od3 = place_product_order(purchaser3, facility, product3, account)
    end

    it_behaves_like "active/inactive users" do
      let(:user) { purchaser }
    end

    it "returns all three user details" do
      expect(users).to contain_all [purchaser, purchaser2, purchaser3]
      expect(searcher.order_details).to contain_all [@od1, @od2, @od3]
    end

    it "returns just one product" do
      params[:products] = [product.id]
      expect(users).to eq([purchaser])
      expect(searcher.order_details).to contain_all [@od1]
    end

    it "returns two products" do
      params[:products] = [product.id, product2.id]
      expect(users).to contain_all [purchaser, purchaser2]
      expect(searcher.order_details).to contain_all [@od1, @od2]
    end
  end

  context "account owners" do
    let(:owner2) { FactoryGirl.create(:user) }
    let(:owner3) { FactoryGirl.create(:user) }

    before :each do
      account2 = FactoryGirl.create(:nufs_account, account_users_attributes: [FactoryGirl.attributes_for(:account_user, user: owner2)])
      account3 = FactoryGirl.create(:nufs_account, account_users_attributes: [FactoryGirl.attributes_for(:account_user, user: owner3)])

      @od1 = place_product_order(purchaser, facility, product, account)
      @od2 = place_product_order(purchaser, facility, product2, account2)
      @od3 = place_product_order(purchaser, facility, product3, account3)
      params.merge!(search_type: :account_owners)
    end

    it_behaves_like "active/inactive users" do
      let(:user) { owner }
    end

    it "finds owners if no other limits" do
      expect(users.map(&:id)).to contain_all [owner, owner2, owner3].map(&:id)
      expect(searcher.order_details).to contain_all [@od1, @od2, @od3]
    end

    it "finds owners with limited order details" do
      params[:products] = [product.id, product2.id]
      expect(users).to contain_all [owner, owner2]
      expect(searcher.order_details).to contain_all [@od1, @od2]
    end

  end

  context "customers_and_account_owners" do
    let(:owner2) { FactoryGirl.create(:user) }
    let(:owner3) { FactoryGirl.create(:user) }

    before :each do
      account2 = FactoryGirl.create(:nufs_account, account_users_attributes: [FactoryGirl.attributes_for(:account_user, user: owner2)])
      account3 = FactoryGirl.create(:nufs_account, account_users_attributes: [FactoryGirl.attributes_for(:account_user, user: owner3)])

      @od1 = place_product_order(purchaser, facility, product, account)
      @od2 = place_product_order(purchaser2, facility, product2, account2)
      @od3 = place_product_order(purchaser3, facility, product3, account3)
      params.merge!(search_type: :customers_and_account_owners)
    end

    it_behaves_like "active/inactive users" do
      let(:user) { owner }
    end

    it "finds owners and purchaser if no other limits" do
      expect(users).to contain_all [owner, owner2, owner3, purchaser, purchaser2, purchaser3]
      expect(searcher.order_details).to contain_all [@od1, @od2, @od3]
    end

    it "finds owners and purchasers with limited order details" do
      params[:products] = [product.id, product2.id]
      expect(users).to contain_all [owner, owner2, purchaser, purchaser2]
      expect(searcher.order_details).to contain_all [@od1, @od2]
    end

  end

  context "search authorized users" do
    let(:user) { FactoryGirl.create(:user) }
    let(:user2) { FactoryGirl.create(:user) }
    let(:user3) { FactoryGirl.create(:user) }

    before :each do
      product.update_attributes(requires_approval: true)
      product2.update_attributes(requires_approval: true)
      # Users 1 and 2 have access to product1
      # Users 2 and 3 have access to product2
      ProductUser.create(product: product, user: user, approved_by: owner.id, approved_at: Time.zone.now)
      ProductUser.create(product: product, user: user2, approved_by: owner.id, approved_at: Time.zone.now)
      ProductUser.create(product: product2, user: user2, approved_by: owner.id, approved_at: Time.zone.now)
      ProductUser.create(product: product2, user: user3, approved_by: owner.id, approved_at: Time.zone.now)
      params.merge!(search_type: :authorized_users)
    end

    it_behaves_like "active/inactive users"

    it "returns all authorized users for any instrument" do
      params[:products] = []
      expect(users).to contain_all [user, user2, user3]
    end

    it "returns only the users for the first product" do
      params[:products] = [product.id]
      expect(users).to contain_all [user, user2]
    end

    it "returns only the users for the second product" do
      params[:products] = [product2.id]
      expect(users).to contain_all [user2, user3]
    end
  end

  # SLOW
  # Oracle blows up if you do a WHERE IN (...) clause with more than a 1000 items
  # so let's test it.
  # commented out because the creation of users takes so long. run it every once in a while
  # describe "being ready for Oracle" do
  #   before :each do
  #     Array.new(1001) do
  #       user = FactoryGirl.create(:user)
  #       od = place_product_order(user, facility, product, account)
  #     end
  #     expect(OrderDetail.all.size).to eq(1001)
  #   end
  #   it "returns 1001 users" do
  #     users = @controller.do_search(@params)
  #     expect(users.size).to eq(1001)
  #   end
  # end

end
