require 'spec_helper'

describe Journal do

  before :each do
    @facility = Factory.create(:facility)
    @journal  = Journal.new(:facility => @facility, :created_by => 1, :journal_date => Time.zone.now)
  end

  it "can be created with valid attributes" do
    @journal.should be_valid
    @journal.save
    @journal.id.should_not be_nil
  end
  
  it "allows only one active single-facility journal per facility" do
    assert @journal.save
    @journal.id.should_not be_nil
    
    @journal2 = Journal.create(:facility => @facility, :created_by => 1, :journal_date => Time.zone.now)
    @journal2.should_not be_valid
    
    @journal.update_attributes({:is_successful => false, :reference => '12345', :updated_by => 1})
    @journal.should be_valid
    @journal2.should be_valid
  end

  
  context "multi-facility journals" do
    before :each do
      @admin = Factory(:user)
      @facilitya = Factory.create(:facility, :abbreviation => "A")
      @facilityb = Factory.create(:facility, :abbreviation => "B")
      @facilityc = Factory.create(:facility, :abbreviation => "C")
      @facilityd = Factory.create(:facility, :abbreviation => "D")
      @account = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @admin, :created_by => @admin, :user_role => 'Owner']], :facility_id => @facilitya.id)
      
      # little helper to create the calls which the controller performs 
      def create_pending_journal_for(*facilities_list)
        @ods = []
        
        facilities_list.each do |f|
          od = place_and_complete_item_order(@admin, f, @account, true)
          define_open_account(@item.account, @account.account_number)

          @ods << od
        end

        # .should raise_error and .should_not raise_error
        # expect to be called on a block / Proc
        return Proc.new do
          journal  = Journal.create!(
            :facility_id => (facilities_list.size == 1 ? facilities_list.first.id : nil),
            :created_by => @admin.id,
            :journal_date => Time.zone.now
          )
          
          journal.create_journal_rows!(@ods)

          journal
        end
      end
    end

    context "(with: pending journal for A & B)" do
      before :each do
        create_pending_journal_for( @facilitya, @facilityb ).should_not raise_error(Exception, /pending journal/)
      end

      it "should not allow creation of a journal for B & C (journal pending on B)" do
        create_pending_journal_for( @facilityb, @facilityc ).should raise_error(Exception, /pending journal/)

      end

      it "should not allow creation of a journal for A (journal pending on A)" do
        create_pending_journal_for( @facilitya ).should raise_error(Exception, /pending journal/)

      end
        
      it "should not allow creation of a journal for B (journal pending on B)" do
        create_pending_journal_for( @facilityb ).should raise_error(Exception, /pending journal/)

      end

      it "should allow creation of a journal for C" do
        create_pending_journal_for( @facilityc ).should_not raise_error(Exception, /pending journal/)

      end

      it "should allow creation of a journal for C & D (no journals on either C or D)" do
        create_pending_journal_for( @facilityc, @facilityd ).should_not raise_error(Exception, /pending journal/)
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
    @owner    = Factory.create(:user)
    hash      = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
    @account  = Factory.create(:nufs_account, :account_users_attributes => [hash])
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
end
