RSpec.shared_examples_for "A product supporting ScheduleRulesController" do |product_sym|
  render_views

  let(:facility) { FactoryGirl.create(:facility) }
  let(:facility_account) { facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account)) }
  let(:product) { FactoryGirl.create(product_sym, facility: facility, facility_account_id: facility_account.id) }
  let(:senior_staff) { create(:user, :senior_staff, facility: facility) }

  let(:product_params) { { facility_id: facility.url_name, :"#{product_sym}_id" => product.url_name } }

  describe "index" do
    let(:staff) { create(:user, :staff, facility: facility) }

    before do
      sign_in staff
      get :index, product_params
    end

    it "sets the product and renders" do
      expect(assigns(:product)).to eq(product)
      expect(response).to be_success
      expect(response).to render_template("schedule_rules/index")
    end
  end

  describe "new" do
    before do
      sign_in senior_staff
      get :new, product_params
    end

    it "sets the product and renders" do
      expect(assigns(:product)).to eq(product)
      expect(response).to be_success
      expect(response).to render_template("schedule_rules/new")
    end

    it "sets the defaults to 9-5" do
      expect(assigns(:schedule_rule).start_hour).to eq(9)
      expect(assigns(:schedule_rule).start_min).to eq(0)
      expect(assigns(:schedule_rule).end_hour).to eq(17)
      expect(assigns(:schedule_rule).end_min).to eq(0)
    end
  end

  describe "create" do
    def do_request
      sign_in senior_staff
      post :create, product_params.merge(schedule_rule: rule_params)
    end

    let(:rule_params) { FactoryGirl.attributes_for(:schedule_rule, product_id: product.id) }

    it "creates the schedule rule and redirects to index" do
      expect { do_request }.to change(ScheduleRule, :count).by(1)
      expect(response).to redirect_to [facility, product, :schedule_rules]
    end

    context "with product access groups" do
      let!(:product_access_groups) { FactoryGirl.create_list(:product_access_group, 3, product_id: product.id) }

      it "should come out with no restriction levels" do
        do_request
        expect(assigns(:schedule_rule).product_access_groups).to be_empty
      end

      describe "with the groups in the request" do
        let(:rule_params) do
          super().merge(product_access_group_ids: [product_access_groups[0].id, product_access_groups[2].id])
        end

        it "should store restriction_rules" do
          do_request
          expect(assigns(:schedule_rule).product_access_groups).to contain_exactly(product_access_groups[0], product_access_groups[2])
        end
      end
    end
  end

  describe "with an existing ScheduleRule" do
    let(:rule) { product.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule)) }

    describe "edit" do
      before do
        sign_in senior_staff
        get :edit, product_params.merge(id: rule.id)
      end

      it "assigns the schedule rule and renders" do
        expect(assigns(:schedule_rule)).to eq(rule)
        is_expected.to render_template "edit"
      end
    end

    describe "update" do
      let(:rule_params) { FactoryGirl.attributes_for(:schedule_rule, :weekend) }
      def do_request
        sign_in senior_staff
        put :update, product_params.merge(
          id: rule.id,
          schedule_rule: rule_params,
        )
      end

      it "updates the rule" do
        expect { do_request }.to change { rule.reload.on_mon }.to be(false)
      end

      it "redirects to the index" do
        do_request
        expect(response).to redirect_to [facility, product, :schedule_rules]
      end

      context "with product access groups" do
        let!(:product_access_groups) { FactoryGirl.create_list(:product_access_group, 3, product_id: product.id) }

        it "should come out with no restriction levels" do
          do_request
          expect(assigns[:schedule_rule].product_access_groups).to be_empty
        end

        it "should come out with no restriction levels if it had them before" do
          rule.product_access_groups = product_access_groups
          rule.save!
          do_request
          expect(assigns[:schedule_rule].product_access_groups).to be_empty
        end

        describe "submitting an update" do
          let(:rule_params) do
            super().merge(product_access_group_ids: [product_access_groups[0].id, product_access_groups[2].id])
          end

          it "should store the updated restriction_rules" do
            do_request
            expect(assigns[:schedule_rule].product_access_groups).to contain_exactly(product_access_groups[0], product_access_groups[2])
          end
        end
      end
    end

    context "destroy" do
      def do_request
        sign_in senior_staff
        delete :destroy, product_params.merge(id: rule.id)
      end

      it "destroys the object" do
        rule # make sure it's created
        expect { do_request }.to change(ScheduleRule, :count).by(-1)
      end

      it "redirects to the index view" do
        do_request
        expect(response).to redirect_to [facility, product, :schedule_rules]
      end
    end
  end
end
