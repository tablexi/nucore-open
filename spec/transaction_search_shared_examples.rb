RSpec.shared_examples_for TransactionSearch do |date_range_field|
  context "when searching" do
    let(:date_string) { "2001-01-01" }
    let(:datetime) { Time.zone.parse(date_string) }

    it "supports the inner method" do
      expect(controller).to respond_to(:"#{action}_with_search")
    end

    context "when setting the account_owners parameter" do
      let(:params) { super().merge(account_owners: [3, 4]) }

      it "applies the parameter" do
        expect(assigns(:order_details).where_values)
          .to be_include("account_users.user_id in ('3','4')")
      end
    end

    context "when setting the accounts parameter" do
      let(:params) { super().merge(accounts: [1, 6]) }

      it "applies the parameter" do
        expect(assigns(:order_details).where_values)
          .to be_include("order_details.account_id in ('1','6')")
      end
    end

    context "when setting the end date parameter" do
      let(:params) { super().merge(date_range: { end: date_string }) }

      it "applies the parameter" do
        expect(assigns(:order_details))
          .to contain_end_of_day(date_range_field, datetime)
      end
    end

    context "when setting the facilities parameter" do
      let(:params) { super().merge(facilities: [2, 3]) }

      it "applies the parameter" do
        expect(assigns(:order_details).where_values)
          .to be_include("orders.facility_id in ('2','3')")
      end
    end

    context "when setting the order_statuses parameter" do
      let(:params) { super().merge(order_statuses: [1, 2]) }

      it "applies the parameter" do
        expect(assigns(:order_details).where_values)
          .to be_include("order_details.order_status_id in ('1','2')")
      end
    end

    context "when setting the products parameter" do
      let(:params) { super().merge(products: [2, 4]) }

      it "applies the parameter" do
        expect(assigns(:order_details).where_values)
          .to be_include("order_details.product_id in ('2','4')")
      end
    end

    context "when setting the start date parameter" do
      let(:params) { super().merge(date_range: { start: date_string }) }

      it "applies the parameter" do
        expect(assigns(:order_details))
          .to contain_beginning_of_day(date_range_field, datetime)
      end
    end
  end
end
