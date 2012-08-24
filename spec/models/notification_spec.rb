require 'spec_helper'

describe Notification do

  before :each do
    @user=Factory.create :user

    class MockNotifier
      include Notifier

      attr_accessor :id

      def to_notice(user)
        "#{user.username} should visit #{root_url}"
      end
    end

    @notifier=MockNotifier.new
    @notifier.id=9999
    Notification.create_for! @user, @notifier
  end


  [ :user_id, :created_by, :created_by_type, :notice ].each do |field|
    it { should validate_presence_of field }
  end


  it 'should create for user by notifier' do
    notices=Notification.all
    notices.size.should == 1
    notice=notices.first
    notice.user.should == @user
    notice.created_by.should == @notifier.id
    notice.created_by_type.should == @notifier.class.name
    notice.notice.should == @notifier.to_notice(@user)
  end


  context 'scopes' do

    before :each do
      @notifier2=MockNotifier.new
      @notifier2.id=1111
      Notification.create_for! @user, @notifier2
    end

    it 'should find notifications by notifier' do
      notices=Notification.by(@notifier2).all
      notices.size.should == 1
      notice=notices.first
      notice.created_by.should == @notifier2.id
      notice.created_by_type.should == @notifier2.class.name
    end

    it 'should find non dismissed notifications' do
      notification=Notification.by(@notifier2).first
      notification.update_attribute :dismissed_at, Time.zone.now
      notices=Notification.active.all
      notices.size.should == 1
      notice=notices.first
      notice.created_by.should == @notifier.id
      notice.created_by_type.should == @notifier.class.name
    end

  end

end
