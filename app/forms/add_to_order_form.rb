class AddToOrderForm

  include ActiveModel::Model
  include TextHelpers::Translation

  attr_reader :original_order, :current_facility
  attr_accessor :quantity, :product_id, :order_status_id, :note, :duration, :created_by, :fulfilled_at
  attr_accessor :flash

  validates :product_id, presence: true
  validates :order_status_id, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }

  def initialize(original_order)
    @original_order = original_order
    @current_facility = original_order.facility
    @quantity = 1
    @duration = 1
  end

  def save
    @flash = {}
    raise(ActiveRecord::RecordInvalid, self) unless valid?

    order_appender = OrderAppender.new(original_order, created_by)
    notifications = order_appender.add!(product, quantity, params)
    if notifications
      flash[:error] = text("update.notices", product: product.name)
    else
      flash[:notice] = text("update.success", product: product.name)
    end
    true
  rescue AASM::InvalidTransition
    flash[:error] = invalid_transition_message(product, params[:order_status_id])
    false
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.record.errors.full_messages.to_sentence
    false
  rescue => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    flash[:error] = text("update.error", product: product.name)
    false
  end

  protected

  def translation_scope
    "controllers.facility_orders"
  end

  private

  def params
    {
      note: note,
      duration: duration,
      order_status_id: order_status_id,
      fulfilled_at: fulfilled_at,
    }
  end

  def product
    @product ||= current_facility.products.find(product_id)
  end

  def invalid_transition_message(product, order_status_id)
    text("update.invalid_status",
         product: product,
         status: OrderStatus.find(order_status_id))
  end

end
