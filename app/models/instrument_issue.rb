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
      recipients: recipients,
    ).deliver_later
  end

  def recipients
    # Per NU, `Facility#email` is intentionally left out #137686
    all = product.facility.director_and_admins.pluck(:email) + product.training_request_contacts
    all.uniq
  end

end
