class Notification < ActiveRecord::Base
  belongs_to :user
  belongs_to :subject, :polymorphic => true

  validates_presence_of :user_id, :subject_id, :notice


  scope :about, lambda{|subject| where(:subject_id => subject.id, :subject_type => subject.class.name) }
  scope :active, where('dismissed_at IS NULL')


  def notice
    self[:notice].try(:html_safe)
  end


  def self.create_for!(user, subject)
    create!(
      :user => user,
      :subject => subject,
      :notice => subject.to_notice(self, user)
    )
  end
end
