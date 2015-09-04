require "rails_helper"

describe Facility do
  it "should require name" do
    is_expected.to validate_presence_of(:name)
  end

  it "should require abbreviation" do
    is_expected.to validate_presence_of(:abbreviation)
  end

  context "when finding problem orders and reservations" do
    subject(:facility) { order.facility }
    let(:order) { create(:purchased_order, product: product) }

    def convert_to_problem_order(order)
      order.order_details.each do |order_detail|
        order_detail.update_attributes(price_policy: nil, state: "complete")
      end
    end

    describe "#problem_non_reservation_order_details" do
      let(:product) { create(:setup_item) }

      context "when there are no problem non-reservations" do
        it { expect(facility.problem_non_reservation_order_details).to be_empty }
      end

      context "when there are problem orders" do
        let(:problem_orders) { order.order_details }

        before { convert_to_problem_order(order) }

        it "returns the problem non-reservation order details" do
          expect(facility.problem_non_reservation_order_details)
            .to match_array(problem_orders)
        end
      end
    end

    describe "#problem_reservation_order_details" do
      let(:product) { create(:setup_instrument) }

      context "when there are no problem reservations" do
        it { expect(facility.problem_reservation_order_details).to be_empty }
      end

      context "when there are problem reservations" do
        let(:problem_reservations) { order.order_details }

        before { convert_to_problem_order(order) }

        it "returns the problem reservation order details" do
          expect(facility.problem_reservation_order_details)
            .to match_array(problem_reservations)
        end
      end
    end
  end

  describe ".training_requests" do
    let(:products) { create_list(:instrument_requiring_approval, 3) }

    before(:each) do
      products.each { |product| create(:training_request, product: product) }
    end

    it "scopes training requests to a facility" do
      products.each do |product|
        expect(product.facility.training_requests.map(&:product))
          .to match_array([product])
      end
    end
  end

  context "url_name" do
    it "is only valid with alphanumeric and -_ characters" do
      is_expected.not_to allow_value('abc 123').for(:url_name)
      is_expected.to allow_value('abc-123').for(:url_name)
      is_expected.to allow_value('abc123').for(:url_name)
    end

    it "is not valid with less than 3 or longer than 50 characters" do
      is_expected.not_to allow_value('123456789012345678901234567890123456789012345678901').for(:url_name) # 51 chars
      is_expected.not_to allow_value('12').for(:url_name)
      is_expected.not_to allow_value('').for(:url_name)
      is_expected.not_to allow_value(nil).for(:url_name)
     end

    it "is valid between 3 and 50 characters" do
      is_expected.to allow_value('123').for(:url_name)
      is_expected.to allow_value('12345678901234567890123456789012345678901234567890').for(:url_name) # 50 chars
    end

    it "is unique" do
      @factory1 = FactoryGirl.create(:facility)
      @factory2 = FactoryGirl.build(:facility, :url_name => @factory1.url_name)
      expect(@factory2).not_to be_valid
    end
  end

  context "when looking up ids or urls" do
    let!(:facilities) { create_list(:facility, 3) }

    describe ".ids_from_urls" do
      it "returns the expected ids" do
        expect(Facility.ids_from_urls(facilities.map(&:url_name)))
          .to match_array(facilities.map(&:id))
      end
    end

    describe ".urls_from_ids" do
      it "returns the expected url_names" do
        expect(Facility.urls_from_ids(facilities.map(&:id)))
          .to match_array(facilities.map(&:url_name))
      end
    end
  end
end
