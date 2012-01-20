class Product < ActiveRecord::Base

  belongs_to :facility
  belongs_to :initial_order_status, :class_name => 'OrderStatus'
  belongs_to :facility_account
  has_many   :product_users
  has_many   :order_details
  has_many   :file_uploads
  has_many   :price_groups, :through => :price_group_products
  has_many   :price_group_products

  validates_presence_of :name, :type
  validate_url_name :url_name
  validates_inclusion_of :requires_approval, :is_archived, :is_hidden, :in => [true, false, 0, 1]
  
  scope :active,             :conditions => { :is_archived => false, :is_hidden => false }
  scope :active_plus_hidden, :conditions => { :is_archived => false}
  scope :archived,           :conditions => { :is_archived => true }
  scope :not_archived,       :conditions => { :is_archived => false }

  after_create :set_default_pricing
  
  def initial_order_status
    self[:initial_order_status_id] ? OrderStatus.find(self[:initial_order_status_id]) : OrderStatus.default_order_status
  end

  def current_price_policies
    current_policies = {}
    PricePolicy.find(:all, :conditions => ["#{self.class.name.downcase}_id = ? AND start_date <= ? AND expire_date > ?", self.id, Time.zone.now, Time.zone.now]).each { |pp|
      unless current_policies[pp.price_group_id].nil?
        current_policies[pp.price_group_id] = pp if pp.start_date > current_policies[pp.price_group_id].start_date
      else
        current_policies[pp.price_group_id] = pp
      end
    }
    current_policies.values
  end

  def <=> (obj)
    name.casecmp obj.name
  end

  def description
    self[:description].html_safe if self[:description]
  end
  
  def parameterize
    self.class.to_s.parameterize.to_s.pluralize
  end

  def can_be_used_by?(user)
    return true unless requires_approval?
    !(product_users.find_by_user_id(user.id).nil?)
  end

  def to_param
    if errors[:url_name].nil?
      url_name
    else
      url_name_was
    end
  end

  def to_s
    name.html_safe || ''
  end
  
  def to_s_with_status
    to_s + (is_archived? ? ' (inactive)' : '')
  end

  def set_default_pricing
    [ PriceGroup.base.first, PriceGroup.external.first ].each do |pg|
      PriceGroupProduct.create!(:product => self, :price_group => pg)
    end
  end
  
  def is_approved_for? (user)
    return true if user.nil?
    if requires_approval?
      return requires_approval? && !product_users.find_by_user_id(user.id).nil?
    else
      true
    end
  end
  
end
