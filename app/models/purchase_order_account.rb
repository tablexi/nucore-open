class PurchaseOrderAccount < Account
  belongs_to :facility

  validates_presence_of   :account_number

  def to_s
    string = "#{description} (#{account_number})"
    if facility
      string += " - #{facility.name}"
    end
    string
  end
end
