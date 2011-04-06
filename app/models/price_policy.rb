class PricePolicy < ActiveRecord::Base

  belongs_to :price_group
  validates_presence_of :start_date, :price_group_id, :type
  validates_inclusion_of :restrict_purchase, :in => [true, false, 0, 1]
  validate :start_date_is_unique, :unless => lambda { |o| o.start_date.nil? }

  named_scope :active, lambda {{ :conditions => [ "start_date <= ?", Time.zone.now ], :order => "start_date DESC" }}

  def start_date_is_unique
    type          = self.class.name.downcase.gsub(/pricepolicy$/, '')
    product       = self.send("#{type}")
    price_group   = self.price_group
    unless (product.nil? || price_group.nil?)
      if id.nil?
        pp = PricePolicy.find(:first, :conditions => ["price_group_id = ? AND #{type}_id = ? AND start_date = ?", price_group.id, product.id, start_date])
      else
        pp = PricePolicy.find(:first, :conditions => ["price_group_id = ? AND #{type}_id = ? AND start_date = ? AND id <> ?", price_group.id, product.id, start_date, id])
      end
      errors.add("start_date", "conflicts with an existing price rule") unless pp.nil?
    end
  end
  
#  def self.active(product)
#    policies = product.send("#{product.class.name.downcase}_price_policies")
#    max      = nil
#    policies.each { |p| 
#      max = p if p.start_date <= Time.zone.now && (max.nil? || p.start_date > max.start_date) 
#    }
#    max
#  end
  
end
