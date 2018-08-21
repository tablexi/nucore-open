# frozen_string_literal: true

class ProductApprover

  class Stats

    attr_reader :access_groups_changed, :granted, :revoked

    def initialize
      @access_groups_changed = 0
      @granted = 0
      @revoked = 0
    end

    def grant
      @granted += 1
    end

    def revoke
      @revoked += 1
    end

    def access_group_change
      @access_groups_changed += 1
    end

    def access_groups_changed?
      @access_groups_changed > 0
    end

    def grants_changed?
      @granted + @revoked > 0
    end

  end

  def initialize(all_products, user, approver)
    @all_products = all_products
    @user = user
    @approver = approver
  end

  def update_approvals(products_to_approve, access_group_hash = nil)
    access_group_hash ||= {}
    @all_products.each_with_object(Stats.new) do |product, stats|
      if products_to_approve.include?(product)
        approve_access(product) && stats.grant
        update_access_group(product, access_group_hash[product.id.to_s]) && stats.access_group_change
      else
        revoke_access(product) && stats.revoke
      end
    end
  end

  def approve_access(product)
    create_product_user(product) unless product.can_be_used_by?(@user)
  end

  def revoke_access(product)
    destroy_product_user(product) if product.can_be_used_by?(@user)
  end

  def update_access_group(product, access_group_id)
    product_user = product.find_product_user(@user) || return
    update_product_user_access_group(
      product_user,
      ProductAccessGroup.find_by(id: access_group_id),
    )
  end

  def update_product_user_access_group(product_user, product_access_group)
    return if product_user.product_access_group == product_access_group
    product_user.product_access_group = product_access_group
    product_user.save
  end

  private

  def create_product_user(product)
    ProductUserCreator.create(product: product, user: @user, approver: @approver)
  end

  def destroy_product_user(product)
    get_product_user(product).try(:destroy)
  end

  def get_product_user(product)
    product.product_users.find_by(user_id: @user.id)
  end

end
