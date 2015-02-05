module PriceGroupMembersController
  extend ActiveSupport::Concern

  included do
    admin_tab     :all
    before_filter :authenticate_user!
    before_filter :check_acting_as
    before_filter :init_current_facility
    before_filter :load_price_group_and_ability!

    layout "two_column"

    load_and_authorize_resource
  end

  def initialize
    @active_tab = "admin_facility"
    super
  end

  private

  def destroy_price_group_member!
    price_group_member
    .class
    .find(:first, conditions: { price_group_id: @price_group.id, id: params[:id] })
    .destroy
  end

  def load_price_group_and_ability!
    @price_group = current_facility.price_groups.find(params[:price_group_id])
    @price_group_ability = Ability.new(current_user, @price_group, self)
  end
end
