class SimpleInstrumentPricePolicy < PricePolicy

  validates :usage_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_cost, :usage_subsidy, :cancellation_cost, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }
  validates :reservation_rate, :reservation_subsidy, :overage_rate, :overage_subsidy, inclusion: [ nil ]
  validates :usage_rate, presence: true, unless: :restrict_purchase?
  validate :subsidy_less_than_rate?, unless: :restrict_purchase?


  def estimate_cost_and_subsidy(*args)
  end


  def calculate_cost_and_subsidy(*args)
  end


  def subsidy_less_than_rate?
    if usage_subsidy && usage_rate && usage_subsidy > usage_rate
      errors.add("usage_subsidy", "cannot be greater than the Usage cost")
    end
  end
end
