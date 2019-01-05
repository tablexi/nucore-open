class AddToOrderForm

  include ActiveModel::Model

  attr_accessor :original_order
  attr_accessor :quantity, :product_id, :order_status_id, :note, :account_id, :duration, :created_by, :fulfilled_at

  validates :account_id, presence: true
  validates :product_id, presence: true
  validates :order_status_id, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }

  def initialize(original_order)
    @original_order = original_order
    @account_id = original_order.account_id
    @quantity = 1
    @duration = 1
  end

  def save
    return unless valid?
    order_appender = OrderAppender.new(original_order, created_by)

    begin
      notifications = order_appender.add!(product, quantity, params)
      if notifications
        errors.add :base, "there are notifications"
      else
        errors.add :base, "no notifications"
      end
      true
    rescue AASM::InvalidTransition
      errors.add :base, invalid_transition_message(product, params[:order_status_id])
    rescue ActiveRecord::RecordInvalid => e
      errors.add :base, e.record.errors.full_messages.to_sentence
    rescue => e
      Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
      errors.add :base, "an update error" #text("update.error", product: product.name)
    end
  end

  private

  def params
    {
      note: note,
      account_id: account_id,
      duration: duration,
      order_status_id: order_status_id,
      fulfilled_at: fulfilled_at,
    }
  end

  def product
    @product ||= Product.find(product_id)
  end

  def invalid_transition_message(product, order_status_id)
    text("update.invalid_status",
         product: product,
         status: OrderStatus.find(order_status_id))
  end

end
