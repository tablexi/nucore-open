class PriceGroup < ActiveRecord::Base
  belongs_to :facility
  has_many   :order_details, :through => :price_policies, :dependent => :restrict
  has_many   :price_group_members, :dependent => :destroy
  has_many   :price_policies, :dependent => :destroy

  validates_presence_of   :facility_id # enforce facility constraint here, though it's not always required
  validates_presence_of   :name
  validates_uniqueness_of :name, :scope => :facility_id

  default_scope :order => 'is_internal DESC, display_order ASC, name ASC'
  
  before_destroy :is_not_global
  before_create  lambda {|o| o.display_order = 999 if !o.facility_id.nil?}

  scope :base,  :conditions => { :name => Settings.price_group.name.base, :facility_id => nil }
  scope :external,      :conditions => { :name => Settings.price_group.name.external, :facility_id => nil }
  scope :cancer_center, :conditions => { :name => Settings.price_group.name.cancer_center, :facility_id => nil }

  scope :globals, :conditions => { :facility_id => nil }

  def user_price_group_members
    UserPriceGroupMember.find(:all, :conditions => { :price_group_id => id, :type => 'UserPriceGroupMember' })
  end

  def account_price_group_members
    AccountPriceGroupMember.find(:all, :conditions => { :price_group_id => id, :type => 'AccountPriceGroupMember' })
  end

  def is_not_global
    !global?
  end

  def global?
    self.facility.nil?
  end

  def can_purchase?(product)
    return !PriceGroupProduct.find_by_price_group_id_and_product_id(self.id, product.id).nil?
  end

  def name
    is_master_internal? ? "#{I18n.t('institution_name')} #{self[:name]}" : self[:name]
  end

  def to_s
    self.name  
  end

  def type_string
    is_internal? ? 'Internal' : 'External'
  end

  def is_master_internal?
    self.is_internal? && self.display_order == 1
  end

  def <=> (obj)
    "#{display_order}-#{name}".casecmp("#{obj.display_order}-#{obj.name}")
  end

  def can_delete?
    # use !.any? because it uses SQL count(), unlike none?
    !global? && !order_details.any?
  end
end
