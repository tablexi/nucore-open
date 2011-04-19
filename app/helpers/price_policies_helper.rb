module PricePoliciesHelper


  def format_date(date)
    return date.is_a?(String) ? date : date.strftime("%m/%d/%Y")
  end

end