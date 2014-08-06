class SchedulingGroupUpdater

  def initialize(product_id, user)
    @product_user = Product.find(product_id).find_product_user(user)
  end

  def update_access_group(access_group_id)
    load_product_access_group(access_group_id)
    if change_access_group?
      @product_user.product_access_group = @product_access_group
      @product_user.save
    end
  end

  private

  def load_product_access_group(access_group_id)
    if @product_user.present?
      @product_access_group = ProductAccessGroup.find_by_id(access_group_id)
    end
  end

  def change_access_group?
    @product_user.present? &&
    @product_user.product_access_group != @product_access_group
  end

end
