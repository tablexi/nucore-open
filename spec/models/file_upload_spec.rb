require 'spec_helper'

describe StoredFile do

  it "should require name" do
    should validate_presence_of(:name)
  end

  it "should require file_type" do
    should validate_presence_of(:file_type)
  end

  context "product_id" do
    it "should be required for 'info' file_type" do
      @fu = StoredFile.create(:file_type => 'info')
      @fu.should validate_presence_of(:product_id)
    end
    
    it "should be required for 'template' file_type" do
      @fu = StoredFile.create(:file_type => 'template')
      @fu.should validate_presence_of(:product_id)
    end
  end

  context "order_detail_id" do
    it "should be required for 'template_result' file_type" do
      @fu = StoredFile.create(:file_type => 'template_result')
      @fu.should validate_presence_of(:order_detail_id)
    end
    it "should be required for 'sample_result' file_type" do
      @fu = StoredFile.create(:file_type => 'sample_result')
      @fu.should validate_presence_of(:order_detail_id)
    end
  end

  it "should create file and store on disk with partitioned path" do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    @creator          = Factory.create(:user)
    @file1            = "#{Rails.root}/spec/files/alpha_survey.rb"
    @file_upload      = @item.stored_files.create(:name => "File 1", :file => File.open(@file1), :file_type => "info",
                                                  :created_by => @creator)
    assert @file_upload.valid?
    assert @file_upload.file.url.match(/^\/files\/\d+\/\d+\/\d+\//)
  end
end
