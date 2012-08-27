require 'spec_helper'

describe MergeNotification do

  before :each do
    @subject=notification_subject
    MergeNotification.create_for! @user, @subject
  end


  [ :user_id, :subject_id, :notice ].each do |field|
    it { should validate_presence_of field }
  end


  it 'should create for user by subject' do
    notices=MergeNotification.all
    notices.size.should == 1
    notice=notices.first
    notice.user.should == @user
    notice.subject.should == @subject
    notice.notice.should == @subject.to_notice(MergeNotification, @user)
  end


  context 'scopes' do

    before :each do
      @subject2=notification_subject
      MergeNotification.create_for! @user, @subject2
    end

    it 'should find notifications by subject' do
      notices=MergeNotification.about(@subject2).all
      notices.size.should == 1
      notices.first.subject.should == @subject2
    end

    it 'should find non dismissed notifications' do
      notification=MergeNotification.about(@subject2).first
      notification.update_attribute :dismissed_at, Time.zone.now
      notices=MergeNotification.active.all
      notices.size.should == 1
      notices.first.subject.should == @subject
    end

  end
  
  
  def notification_subject
    @facility       ||= Factory.create(:facility)
    @facility_account ||= @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @user           ||= Factory.create(:user)
    @item           ||= @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
  
    place_product_order @user, @facility, @item
    clone=@order.clone
    assert clone.save
    @order.update_attribute :merge_with_order_id, clone.id
    @order_detail.reload
  end

end
