class Bundle < Product
  has_many :products, :through => :bundle_products
  has_many :bundle_products, :foreign_key => :bundle_product_id

  def products_for_group_select
    products = facility.products.find(:all, :conditions => ["type <> 'Bundle'"], :order => 'products.type, products.name')
    current_group = []
    current_opts  = []
    groups = []
    products.each do |p|
      if p.class.name != current_group[0]
        unless current_opts.empty?
          current_group << current_opts
          groups << current_group
          current_group = []
          current_opts  = []
        end
        current_group << p.class.name.pluralize
      end
      current_opts << [p.to_s_with_status, p.id]
    end
    groups << (current_group << current_opts) unless current_opts.empty?
    groups
  end

  def products_active?
    return true if products.empty? && !self.is_archived?
    return false if products.empty? || products.any?{|p| p.is_archived?}
    true
  end

  def can_purchase? (group_ids = nil)
    return false if  !available_for_purchase?
    # before if products.empty?, this would return and empty set [], which evaluates to true
    return false if products.empty?
    products.each do |p|
      return false unless p.can_purchase?(group_ids)
    end
  end
end