# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)

require 'rspec/rails'
require 'factory_girl'
require 'shoulda'
require 'mocha'
require 'factories'

# Uncomment the next line to use webrat's matchers
#require 'webrat/integrations/rspec-rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses its own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  #
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner

  config.include Devise::TestHelpers, :type => :controller

  config.before(:all) do
    # users are not created within transactions, so delete them all here before running tests
    UserRole.delete_all
    User.delete_all

    # initialize order status constants
    @os_new        = OrderStatus.find_or_create_by_name(:name => 'New')
    @os_in_process = OrderStatus.find_or_create_by_name(:name => 'In Process')
    @os_complete   = OrderStatus.find_or_create_by_name(:name => 'Complete')
    @os_cancelled  = OrderStatus.find_or_create_by_name(:name => 'Cancelled')
    @os_reconciled  = OrderStatus.find_or_create_by_name(:name => 'Reconciled')

    # initialize price groups
    @nupg = PriceGroup.find_or_create_by_name(:name => 'Northwestern Base Rate', :is_internal => true, :display_order => 1)
    @nupg.save(:validate => false)
    @ccpg = PriceGroup.find_or_create_by_name(:name => 'Cancer Center Rate', :is_internal => true, :display_order => 2)
    @ccpg.save(:validate => false)
    @epg = PriceGroup.find_or_create_by_name(:name => 'External Rate', :is_internal => false, :display_order => 3)
    @epg.save(:validate => false)
  end
end

# used by factory to find or create order status
def find_order_status(status)
  OrderStatus.find_or_create_by_name(status)
end

def assert_true(x)
  assert(x)
end

def assert_false(x)
  assert(!x)
end

def assert_not_valid(x)
  assert !x.valid?
end

def assert_nil(x)
  assert_equal nil, x
end

#
# Asserts that the model +var+
# no longer exists in the DB
def should_be_destroyed(var)
  dead=false

  begin
    var.class.find var.id
  rescue
    dead=true
  end

  assert dead
end


#
# Factory wrapper for creating an account with owner
def create_nufs_account_with_owner(owner=:owner)
  owner=instance_variable_get("@#{owner.to_s}")
  Factory.create(:nufs_account, :account_users_attributes => [ Factory.attributes_for(:account_user, :user => owner) ])
end


#
# Simulates placing an order for an item and having it marked complete
# [_ordered_by_]
#   The user who is ordering the item
# [_facility_]
#   The facility with which the order is placed
# [_account_]
#   The account under which the order is placed
# [_reviewed_]
#   true if the completed order should also be marked as reviewed, false by default
def place_and_complete_item_order(ordered_by, facility, account, reviewed=false)
  @facility_account=facility.facility_accounts.create(Factory.attributes_for(:facility_account))
  @item=facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
  @price_group=Factory.create(:price_group, :facility => facility)
  @order=ordered_by.orders.create(Factory.attributes_for(:order, :created_by => ordered_by.id))
  Factory.create(:user_price_group_member, :user => ordered_by, :price_group => @price_group)
  @item_pp=@item.item_price_policies.create(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id))
  @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => account.id))
  @order_detail.change_status!(OrderStatus.complete.first)

  od_attrs={
    :actual_cost => 20,
    :actual_subsidy => 10,
    :price_policy_id => @item_pp.id
  }

  od_attrs.merge!(:reviewed_at => Time.zone.now-1.day) if reviewed
  @order_detail.update_attributes(od_attrs)
end