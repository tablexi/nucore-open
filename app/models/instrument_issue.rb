# frozen_string_literal: true

class InstrumentIssue

  include ActiveModel::Model

  attr_accessor :message, :user, :product

  validates :message, presence: true
  validates :user, presence: true
  validates :product, presence: true

  def send_notification
    return false unless valid?

    InstrumentIssueMailer.create(
      product: product,
      user: user,
      message: message,
    ).deliver_later
  end

end
