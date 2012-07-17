shared_examples_for "NonReservationProduct" do |product_type|
  before :each do
    # clear out default price groups so they don't get in the way
    PriceGroup.all.each { |pg| pg.delete }
    @product_type = product_type

    @user = Factory.create(:user)
    @facility = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create!(Factory.attributes_for(:facility_account))
    @price_group = @facility.price_groups.create(Factory.attributes_for(:price_group))
    @price_group2 = @facility.price_groups.create(Factory.attributes_for(:price_group))
    
    Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
    Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group2)

    @product = @facility.send(product_type.to_s.pluralize).create!(Factory.attributes_for(@product_type, :facility_account_id => @facility_account.id))
    @order = Factory.create(:order, :created_by_user => @user, :user => @user)
    @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail, :product => @product, :quantity => 1))
  end
  context '#cheapest_price_policy' do
    before :each do
      @price_group3 = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @price_group4 = @facility.price_groups.create(Factory.attributes_for(:price_group))

      @pp_g1 = make_price_policy(:unit_cost => 22, :price_group => @price_group)
      @pp_g2 = make_price_policy(:unit_cost => 23, :price_group => @price_group2)
      @pp_g3 = make_price_policy(:unit_cost => 5, :price_group => @price_group3)
      @pp_g4 = make_price_policy(:unit_cost => 4, :price_group => @price_group4)
    end
    it 'should find the cheapest price policy of the policies user is a member of' do
      @product.groups_for_order_detail(@order_detail).should == [@price_group, @price_group2]
      @product.cheapest_price_policy(@order_detail).should == @pp_g1
    end
    it 'should find the cheapest price policy if the user is in all groups' do
      Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group3)
      Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group4)
      @product.groups_for_order_detail(@order_detail).should == [@price_group, @price_group2, @price_group3, @price_group4]
      @product.cheapest_price_policy(@order_detail).should == @pp_g4
    end

    it 'should find the cheapest price policy if the user is in one group, but the account is in another' do
      @account = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      AccountPriceGroupMember.create!(:price_group => @price_group3, :account => @account)
      @order_detail.update_attributes(:account => @account)
      @product.groups_for_order_detail(@order_detail).should == [@price_group, @price_group2, @price_group3]
      @product.cheapest_price_policy(@order_detail).should == @pp_g3
    end

    context 'with an expired price policy' do
      before :each do
        @pp_g1_expired = make_price_policy(:unit_cost => 1, :price_group => @price_group, :start_date => 7.days.ago, :expire_date => 1.day.ago)
      end
      it 'should ignore the expired price policy, even if it is cheaper' do
        @product.cheapest_price_policy(@order_detail).should == @pp_g1
      end
    end
    context 'with a restricted price_policy' do
      before :each do
        @price_group5 = @facility.price_groups.create(Factory.attributes_for(:price_group))
        Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group5)
        @pp_g3_restricted = make_price_policy(:unit_cost => 1, :price_group => @price_group5, :can_purchase => false)
      end
      it 'should ignore the restricted price policy even if it is cheaper' do
        @product.cheapest_price_policy(@order_detail).should == @pp_g1
      end
    end
  end

  private
  def make_price_policy(attr={})
    @product.send(:"#{@product_type}_price_policies").create!(Factory.attributes_for(:"#{@product_type}_price_policy", attr))
  end
end

shared_examples_for "ReservationProduct" do |product_type|
  before :each do
    # clear out default price groups so they don't get in the way
    PriceGroup.all.each { |pg| pg.delete }
    @product_type = product_type

    @user = Factory.create(:user)
    @facility = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create!(Factory.attributes_for(:facility_account))
    @price_group = @facility.price_groups.create(Factory.attributes_for(:price_group))
    @price_group2 = @facility.price_groups.create(Factory.attributes_for(:price_group))
    
    Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
    Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group2)

    @product = @facility.send(@product_type.to_s.pluralize).create!(Factory.attributes_for(@product_type, :facility_account_id => @facility_account.id))
    @product.schedule_rules.create!(Factory.attributes_for(:schedule_rule))
    
    @order = Factory.create(:order, :created_by_user => @user, :user => @user)
    @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail, :product => @product))
    
    @reservation = Factory.create(:reservation, 
                                  :instrument => @product,  
                                  :reserve_start_at => 1.hour.from_now,
                                  :reserve_end_at => 2.hours.from_now,
                                  :order_detail => @order_detail)
    @order_detail.reload
  end
  context '#cheapest_price_policy' do
    before :each do
      @price_group3 = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @price_group4 = @facility.price_groups.create(Factory.attributes_for(:price_group))

      @pp_g1 = make_price_policy(:usage_rate => 22, :price_group => @price_group)
      @pp_g2 = make_price_policy(:usage_rate => 23, :price_group => @price_group2)
      @pp_g3 = make_price_policy(:usage_rate => 5, :price_group => @price_group3)
      @pp_g4 = make_price_policy(:usage_rate => 4, :price_group => @price_group4)
    end
    it 'should find the cheapest price policy of the policies user is a member of' do
      @product.groups_for_order_detail(@order_detail).should == [@price_group, @price_group2]
      @product.cheapest_price_policy(@order_detail).should == @pp_g1
    end
    it 'should find the cheapest price policy if the user is in all groups' do
      Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group3)
      Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group4)
      @product.groups_for_order_detail(@order_detail).should == [@price_group, @price_group2, @price_group3, @price_group4]
      @product.cheapest_price_policy(@order_detail).should == @pp_g4
    end

    it 'should find the cheapest price policy if the user is in one group, but the account is in another' do
      @account = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      AccountPriceGroupMember.create!(:price_group => @price_group3, :account => @account)
      @order_detail.update_attributes(:account => @account)
      @product.groups_for_order_detail(@order_detail).should == [@price_group, @price_group2, @price_group3]
      @product.cheapest_price_policy(@order_detail).should == @pp_g3
    end

    context 'with an expired price policy' do
      before :each do
        @pp_g1_expired = make_price_policy(:unit_cost => 1, :price_group => @price_group, :start_date => 7.days.ago, :expire_date => 1.day.ago)
      end
      it 'should ignore the expired price policy, even if it is cheaper' do
        @product.cheapest_price_policy(@order_detail).should == @pp_g1
      end
    end
    context 'with a restricted price_policy' do
      before :each do
        @price_group5 = @facility.price_groups.create(Factory.attributes_for(:price_group))
        Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group5)
        @pp_g3_restricted = make_price_policy(:unit_cost => 1, :price_group => @price_group5, :can_purchase => false)
      end
      it 'should ignore the restricted price policy even if it is cheaper' do
        @product.cheapest_price_policy(@order_detail).should == @pp_g1
      end
    end
  end

  private
  def make_price_policy(attr={})
    @product.send(:"#{@product_type}_price_policies").create!(Factory.attributes_for(:"#{@product_type}_price_policy", attr))
  end
end

