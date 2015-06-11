class ProductUserObserver < ActiveRecord::Observer
  def after_create(product_user)
    training_request = get_training_request(product_user) || return
    product_user.update_attribute(:requested_at, training_request.created_at)
    training_request.destroy
  end

  private

  def get_training_request(product_user)
    TrainingRequest
      .where(user_id: product_user.user_id, product_id: product_user.product_id)
      .first
  end
end
