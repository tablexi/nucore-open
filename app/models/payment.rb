class Payment < ActiveRecord::Base
  belongs_to :account, inverse_of: :payments
  belongs_to :statement, inverse_of: :payments
  belongs_to :paid_by, class_name: "User"

  # Add additional sources in an engine with Payment.valid_sources << :new_source
  def self.valid_sources
    @@valid_sources ||= [:check]
  end

  validates :source, presence: true, inclusion: { in: valid_sources }
  validates :account, presence: true
  # TODO use `numericality: { other_than: 0 }` in newer rails
  validates :amount, presence: true, numericality: true, exclusion: { in: [0], message: "may not be 0" }
  validates :processing_fee, presence: true, numericality: true, allow_nil: false

end
