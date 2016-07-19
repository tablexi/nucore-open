# Never instantiate this class directly. Use the `notify` method.
class EmailEvent < ActiveRecord::Base

  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  validates :user, presence: true
  validates :key, presence: true, uniqueness: { scope: :user_id }

  # Use this to avoid sending too many emails to a user within a given timeframe
  # It accepts a block, and will yield if this method has not been called within
  # the wait time.
  #
  # Example:
  #
  # EmailEvent.notify(file.user, [:some_mailer, :some_action], wait: 1.hour) do
  #   SomeMailer.some_action(user).deliver_later
  # end
  #
  def self.notify(user, keys, wait: 24.hours)
    event = find_or_initialize_by(user: user, key: key_for(keys))

    if event.last_sent_at.blank? || event.last_sent_at < wait.ago
      event.last_sent_at = Time.current
      yield
    end
    event.save!
  end

  def self.key_for(keys)
    Array(keys).map(&:to_s).join("/")
  end

end
