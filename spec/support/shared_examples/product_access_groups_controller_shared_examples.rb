RSpec.shared_examples_for "A product supporting ProductAccessGroupsController" do |product_sym|
  render_views

  let(:facility) { FactoryGirl.create(:facility) }
  let(:facility_account) { facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account)) }
  let(:product) { FactoryGirl.create(product_sym, facility: facility, facility_account: facility_account) }
  let(:senior_staff) { FactoryGirl.create(:user, :senior_staff, facility: facility) }
  let(:params) { { facility_id: facility.url_name, :"#{product_sym}_id" => product.url_name } }

  context "index" do
    let(:staff) { FactoryGirl.create(:user, :staff, facility: facility) }

    let(:product2) { FactoryGirl.create(product_sym, facility: facility, facility_account: facility_account) }
    let!(:product_groups) { FactoryGirl.create_list(:product_access_group, 2, product: product) }
    let!(:other_product_group) { FactoryGirl.create(:product_access_group, product: product2) }

    before :each do
      sign_in staff
      get :index, params
    end

    it "succeeds and renders" do
      expect(response).to be_success
      expect(response).to render_template(:index)
    end

    it "assigns the product and access groups" do
      expect(assigns[:product]).to eq(product)
      expect(assigns[:product_access_groups]).to eq(product_groups)
    end
  end

  context "new" do
    before :each do
      sign_in senior_staff
      get :new, params
    end

    it "succeeds and renders" do
      expect(response).to be_success
      expect(response).to render_template(:new)
    end

    it "assigns the product and group" do
      expect(assigns[:product]).to eq(product)
      expect(assigns[:product_access_group]).to be_new_record
    end
  end

  context "create" do
    before do
      sign_in senior_staff
    end

    context "correct info" do
      before do
        post :create, params.merge(product_access_group: FactoryGirl.attributes_for(:product_access_group))
      end

      it "creates and assigns the new record" do
        expect(assigns[:product]).to eq(product)
        expect(assigns[:product_access_group]).to be_persisted
      end

      it "redirects with a flash" do
        expect(flash[:notice]).to be_present
        expect(response).to redirect_to([facility, product, ProductAccessGroup])
      end
    end

    context "missing data" do
      before do
        post :create, params.merge(product_access_group: FactoryGirl.attributes_for(:product_access_group, name: ""))
      end

      it "should assign, but not persist the record" do
        expect(assigns[:product]).to eq(product)
        expect(assigns[:product_access_group]).to be_new_record
        expect(assigns[:product_access_group].errors).to be_present
      end

      it "renders the new template" do
        expect(response).to render_template(:new)
      end
    end
  end

  context "edit" do
    let!(:product_access_group) { FactoryGirl.create(:product_access_group, product: product) }

    before do
      sign_in senior_staff
      get :edit, params.merge(id: product_access_group.id)
    end

    it "assigns the variables and renders the edit template" do
      expect(assigns[:product]).to eq(product)
      expect(assigns[:product_access_group]).to eq(product_access_group)
      expect(response).to render_template :edit
    end
  end

  context "update" do
    let(:product_access_group) { FactoryGirl.create(:product_access_group, product: product) }

    before :each do
      sign_in senior_staff
    end

    context "correct info" do
      before do
        post :update, params.merge(id: product_access_group.id, product_access_group: { name: "new name" })
      end

      it "assigns and updates the access group" do
        expect(assigns[:product]).to eq(product)
        expect(assigns[:product_access_group]).to eq(product_access_group)
        expect(product_access_group.reload.name).to eq("new name")
      end

      it "sets the flash and redirects" do
        expect(flash[:notice]).to be_present
        expect(response).to redirect_to([facility, product, ProductAccessGroup])
      end
    end

    context "missing data" do
      before do
        post :update, params.merge(id: product_access_group.id, product_access_group: { name: "" })
      end

      it "assigns, but does not update the access group" do
        expect(assigns[:product]).to eq(product)
        expect(assigns[:product_access_group]).to eq(product_access_group)
        expect(assigns[:product_access_group].errors).to be_present
        expect(response).to render_template :edit
      end
    end
  end

  context "destroy" do
    let(:product_access_group) { FactoryGirl.create(:product_access_group, product: product) }
    before :each do
      sign_in senior_staff
      delete :destroy, params.merge(id: product_access_group.id)
    end

    it "destroys the record" do
      expect(assigns[:product_access_group]).to be_destroyed
    end

    it "sets the flash and redirects" do
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to([facility, product, ProductAccessGroup])
    end
  end
end
