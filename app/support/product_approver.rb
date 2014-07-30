class ProductApprover

  class Stats
    attr_reader :granted, :revoked

    def initialize
      @granted = 0
      @revoked = 0
    end

    def grant
      @granted += 1
    end

    def revoke
      @revoked += 1
    end

    def any_changed?
      @granted + @revoked > 0
    end
  end

  def initialize(all_products, user, approver)
    @all_products = all_products
    @user = user
    @approver = approver
  end

  def update_approvals(products_to_approve)
    @all_products.each_with_object(Stats.new) do |product, stats|
      if products_to_approve.include?(product)
        approve_access(product) && stats.grant
      else
        revoke_access(product) && stats.revoke
      end
    end
  end

  def approve_access(product)
    create_product_user(product) unless product.is_approved_for?(@user)
  end

  def revoke_access(product)
    destroy_product_user(product) if product.is_approved_for?(@user)
  end

  private

  def create_product_user(product)
    ProductUser.create(product: product, user: @user, approved_by: @approver.id)
  end

  def destroy_product_user(product)
    get_product_user(product).try(:destroy)
  end

  def get_product_user(product)
    product.product_users.find_by_user_id(@user.id)
  end

end
