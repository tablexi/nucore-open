class Product < ActiveRecord::Base

  belongs_to :facility
  belongs_to :initial_order_status, :class_name => 'OrderStatus', :foreign_key => 'initial_order_status_id'
  belongs_to :facility_account
  has_many   :product_users
  has_many   :order_details
  has_many   :file_uploads
  has_many   :price_groups, :through => :price_group_products
  has_many   :price_group_products

  validates_presence_of :name, :type
  validate_url_name :url_name
  validates_inclusion_of :requires_approval, :is_archived, :is_hidden, :in => [true, false, 0, 1]
  
  named_scope :active,             :conditions => { :is_archived => false, :is_hidden => false }
  named_scope :active_plus_hidden, :conditions => { :is_archived => false}
  named_scope :archived,           :conditions => { :is_archived => true }
  named_scope :not_archived,       :conditions => { :is_archived => false }
  
  def initial_order_status
    self[:initial_order_status] or OrderStatus.default_order_status
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
  
  def parameterize
    self.class.to_s.parameterize.to_s.pluralize
  end

  def can_be_used_by?(user)
    return true unless requires_approval?
    !(product_users.find_by_user_id(user.id).nil?)
  end

  def to_param
    if errors.on(:url_name).nil?
      url_name
    else
      url_name_was
    end
  end

  def to_s
    name || ''
  end
  
  def to_s_with_status
    (name || '') + (is_archived? ? ' (inactive)' : '')
  end

  def after_create
    [ PriceGroup.northwestern.first, PriceGroup.external.first ].each do |pg|
      PriceGroupProduct.create!(:product => self, :price_group => pg)
    end
  end
end
