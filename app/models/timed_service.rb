class TimedService < Product

  has_many :timed_service_price_policies, foreign_key: :product_id

  validates_presence_of :initial_order_status_id

end
