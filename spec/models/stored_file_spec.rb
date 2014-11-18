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
      expect(@fu).to validate_presence_of(:product_id)
    end

    it "should be required for 'template' file_type" do
      @fu = StoredFile.create(:file_type => 'template')
      expect(@fu).to validate_presence_of(:product_id)
    end
  end

  context "order_detail_id" do
    it "should be required for 'template_result' file_type" do
      @fu = StoredFile.create(:file_type => 'template_result')
      expect(@fu).to validate_presence_of(:order_detail_id)
    end
    it "should be required for 'sample_result' file_type" do
      @fu = StoredFile.create(:file_type => 'sample_result')
      expect(@fu).to validate_presence_of(:order_detail_id)
    end
  end

  it "should create file and store on disk with partitioned path" do
    @facility         = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @item             = @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
    @creator          = FactoryGirl.create(:user)
    @file1            = "#{Rails.root}/spec/files/template1.txt"
    @file_upload      = @item.stored_files.create(:name => "File 1", :file => File.open(@file1), :file_type => "info",
                                                  :creator => @creator)
    assert @file_upload.valid?
    assert @file_upload.file.url.match(/^\/files\/\d+\/\d+\/\d+\//)
  end
end
