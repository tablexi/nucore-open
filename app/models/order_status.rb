class OrderStatus < ActiveRecord::Base
  acts_as_nested_set

  has_many :order_details
  belongs_to :facility

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:parent_id, :facility_id]
  validates_each :parent_id do |model, attr, value|
    begin
      model.errors.add(attr, 'must be a root') unless (value.nil? || OrderStatus.find(value).root?)
    rescue => e
      model.errors.add(attr, 'must be a valid root')
    end
  end

  scope :new_os,     :conditions => {:name => 'New'},        :limit => 1
  scope :inprocess,  :conditions => {:name => 'In Process'}, :limit => 1
  scope :cancelled,  :conditions => {:name => 'Cancelled'},  :limit => 1
  scope :complete,   :conditions => {:name => 'Complete'},   :limit => 1
  scope :reconciled, :conditions => {:name => 'Reconciled'}, :limit => 1

  def editable?
    !!facility
  end

  def state_name
    root.name.downcase.gsub(/ /,'').to_sym
  end

  def downcase_name
    name.downcase.gsub(/\s+/, '_')
  end

  def is_left_of? (o)
    rgt < o.lft
  end

  def is_right_of? (o)
    lft > o.rgt
  end

  def name_with_level
    "#{'-' * level} #{name}".strip
  end

  def to_s
    name
  end

  class << self
    def root_statuses
      roots.sort {|a,b| a.lft <=> b.lft }
    end

    def default_order_status
      root_statuses.first
    end

    def initial_statuses (facility)
      first_invalid_status = self.find_by_name('Cancelled')
      statuses = self.find(:all).sort {|a,b| a.lft <=> b.lft }.reject {|os|
        !os.is_left_of?(first_invalid_status)
      }
      statuses.reject! { |os| os.facility_id != facility.id && !os.facility_id.nil? } if !facility.nil?
      statuses
    end

    def non_protected_statuses (facility)
      first_protected_status = self.find_by_name('Reconciled')
      statuses = self.find(:all).sort {|a,b| a.lft <=> b.lft }.reject {|os|
        !os.is_left_of?(first_protected_status)
      }
      statuses.reject! { |os| os.facility_id != facility.id && !os.facility_id.nil? } if !facility.nil?
      statuses
    end
  end
end
