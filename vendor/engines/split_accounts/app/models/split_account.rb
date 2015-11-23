class SplitAccount < Account

  has_many :splits, foreign_key: :parent_split_account_id, inverse_of: :parent_split_account

  validate :valid_percent_total
  validate :one_split_has_extra_penny

  def valid_percent_total
    unless percent_total == 100
      errors.add(:splits, "percent total must equal 100")
    end
  end

  def percent_total
    splits.reduce(0) { |sum, split| sum + split.percent }
  end

  def one_split_has_extra_penny
    unless extra_penny_count == 1
      errors.add(:splits, "can have only one with extra penny")
    end
  end

  def extra_penny_count
    splits.select(&:extra_penny).size
  end

end
