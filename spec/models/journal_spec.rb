require 'spec_helper'

describe Journal do

  before :each do
    @facility = FactoryGirl.create(:facility)
    @journal  = Journal.new(:facility => @facility, :created_by => 1, :journal_date => Time.zone.now)
  end

  it "can be created with valid attributes" do
    @journal.should be_valid
    @journal.save
    @journal.id.should_not be_nil
  end

  context "journal creation" do
    before :each do
      @admin = FactoryGirl.create(:user)
      @facilitya = FactoryGirl.create(:facility, :abbreviation => "A")
      @facilityb = FactoryGirl.create(:facility, :abbreviation => "B")
      @facilityc = FactoryGirl.create(:facility, :abbreviation => "C")
      @facilityd = FactoryGirl.create(:facility, :abbreviation => "D")
      @account = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @admin), :facility_id => @facilitya.id)

      # little helper to create the calls which the controller performs
      def create_pending_journal_for(*facilities_list)
        @ods = []

        facilities_list.each do |f|
          od = place_and_complete_item_order(@admin, f, @account, true)
          define_open_account(@item.account, @account.account_number)

          @ods << od
        end

        journal = Journal.create!(
          :facility_id => (facilities_list.size == 1 ? facilities_list.first.id : nil),
          :created_by => @admin.id,
          :journal_date => Time.zone.now
        )

        journal.create_journal_rows!(@ods)

        journal
      end
    end

    context "(with pending journal for A)" do
      before :each do
        create_pending_journal_for(@facilitya)
      end

      it "should not allow creation of a journal for A" do
        expect { create_pending_journal_for( @facilitya) }.to raise_error
      end
    end


    context "(with: pending journal for A & B)" do
      before :each do
        create_pending_journal_for( @facilitya, @facilityb )
      end

      it "should not allow creation of a journal for B & C (journal pending on B)" do
        expect { create_pending_journal_for( @facilityb, @facilityc ) }.to raise_error
      end

      it "should not allow creation of a journal for A (journal pending on A)" do
        expect { create_pending_journal_for( @facilitya ) }.to raise_error
      end

      it "should not allow creation of a journal for B (journal pending on B)" do
        expect { create_pending_journal_for( @facilityb ) }.to raise_error
      end

      it "should allow creation of a journal for C" do
        expect { create_pending_journal_for( @facilityc ) }.to_not raise_error
      end

      it "should allow creation of a journal for C & D (no journals on either C or D)" do
        expect { create_pending_journal_for( @facilityc, @facilityd ) }.to_not raise_error
      end
    end
  end



  it "requires reference on update" do
    assert @journal.save
    assert !@journal.save
    @journal.errors[:reference].should_not be_nil

    @journal.reference = '12345'
    @journal.valid?
    @journal.errors[:reference].should be_empty
  end

  it "requires updated_by on update" do
    assert @journal.save
    assert !@journal.save
    @journal.errors[:updated_by].should_not be_nil

    @journal.updated_by = '1'
    @journal.valid?
    @journal.errors[:updated_by].should be_empty
  end

  it "requires a boolean value for is_successful on update" do
    assert @journal.save
    assert !@journal.save
    @journal.errors[:is_successful].should_not be_nil

    @journal.is_successful = true
    @journal.valid?
    @journal.errors[:is_successful].should be_empty

    @journal.is_successful = false
    @journal.valid?
    @journal.errors[:is_successful].should be_empty
  end

  it "should create and attach journal spreadsheet" do
    @journal.valid?
    # create nufs account
    @owner    = FactoryGirl.create(:user)
    @account  = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @owner))
    @journal.create_spreadsheet
    # @journal.add_spreadsheet("#{Rails.root}/spec/files/nucore.journal.template.xls")
    @journal.file.url.should =~ /^\/files/
  end

  it 'should be open' do
    @journal.is_successful=nil
    @journal.should be_open
  end

  it 'should not be open' do
    @journal.is_successful=true
    @journal.should_not be_open
  end

  context 'order_details_span_fiscal_years?' do
    before :each do
      Settings.financial.fiscal_year_begins = '06-01'
      @owner    = FactoryGirl.create(:user)
      @account  = FactoryGirl.create(:nufs_account, :account_users_attributes => [ FactoryGirl.attributes_for(:account_user, :user => @owner) ])
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @item = @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
      @price_group = FactoryGirl.create(:price_group, :facility => @facility)
      FactoryGirl.create(:user_price_group_member, :user => @owner, :price_group => @price_group)
      @pp = @item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id))

      # Create one order detail fulfulled in each month for a two year range
      d1 = Time.zone.parse('2020-01-01')
      @order_details = []
      (0..23).each do |i|
        order=@owner.orders.create(FactoryGirl.attributes_for(:order, :created_by => @owner.id))
        od = order.order_details.create(FactoryGirl.attributes_for(:order_detail, :product => @item))
        od.update_attributes(:actual_cost => 20, :actual_subsidy => 0)
        od.to_complete!
        od.update_attributes(:fulfilled_at => d1 + i.months)
        @order_details << od
      end
      @order_details.size.should == 24
      # You can use this to view the indexes
      # @order_details.each_with_index do |od, i|
      #   puts "#{i} #{od.fulfilled_at}"
      # end
    end
    it 'should not span fiscal years with everything in the same year' do
      @journal.order_details_span_fiscal_years?(@order_details[5..16]).should be_false
    end
    it 'should span fiscal years when it goes over the beginning' do
      @journal.order_details_span_fiscal_years?([@order_details[6], @order_details[5], @order_details[4]]).should be_true
    end
    it 'should span fiscal years when it goes over the end' do
      @journal.order_details_span_fiscal_years?(@order_details[16..17]).should be_true
    end
    it 'should return false with just one order detail' do
      @journal.order_details_span_fiscal_years?([@order_details[3]])
    end
  end
end
