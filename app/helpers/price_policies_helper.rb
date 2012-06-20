module PricePoliciesHelper


  def format_date(date)
    return date.is_a?(String) ? date : date.strftime("%m/%d/%Y")
  end

  def new_price_policy_path(product)
    send(:"new_facility_#{product.class.name.downcase}_price_policy_path")
  end

  def edit_price_policy_path(price_policy, url_date)
    product = price_policy.product
    send :"edit_facility_#{product.class.name.downcase}_price_policy_path", current_facility, product, url_date
  end

  def price_policy_path(price_policy_or_product, url_date)
    product = price_policy_or_product.respond_to?(:product) ? price_policy_or_product.product : price_policy_or_product
    send :"facility_#{product.class.name.downcase}_price_policy_path", current_facility, product, url_date
  end

  def price_policies_path
    send :"facility_#{@product.class.name.downcase}_price_policies_path"
  end

end