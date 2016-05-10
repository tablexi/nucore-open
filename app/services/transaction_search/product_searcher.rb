module TransactionSearch

  class ProductSearcher < BaseSearcher

    def options
      Product.where(id: order_details.select("distinct product_id")).order(:name)
    end

    def search(params)
      order_details.for_products(params)
    end

    def optimized
      order_details.includes(:product)
    end

  end

end
