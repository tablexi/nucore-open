class Notification < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id, :created_by, :created_by_type, :notice


  scope :by, lambda{|notifier| where(:created_by => notifier.id, :created_by_type => notifier.class.name) }
  scope :active, where('dismissed_at IS NULL')


  def self.create_for!(user, notifier)
    create!(
      :user_id => user.id,
      :created_by => notifier.id,
      :created_by_type => notifier.class.name,
      :notice => notifier.to_notice(user)
    )
  end

end
